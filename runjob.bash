#######################################
# RUN COMMAND
#######################################

###############################
## Run backup job
command_run() {
    if status_is_busy; then
        echo "ERROR: Cannot start new backup job if previous job is not completed."
        exit 1
    fi

    # Record run pid in target dir cfgbackup.pid file
    log_entry "JOB STARTED:  $( date +%Y-%m-%d\ %H:%M:%S )"
    command_runscript PRE_SCRIPT
    if [[ ${CONFIG[BACKUP_TYPE]} == "rotation" ]]; then
        runjob_rotation
    elif [[ ${CONFIG[BACKUP_TYPE]} == "sync" ]]; then
        runjob_sync
    fi
    command_runscript FINAL_SCRIPT
    command_end
}

###############################
## End job and clean up the pid file
command_end() {
    log_entry "JOB ENDED: $( date +%Y-%m-%d\ %H:%M:%S )"
    log_entry ""
    # Cleanup by removing cfgbackup.pid file
    rm $PID_FULL
}

###############################
## Run given script specified by the config, or do nothing if no script was set
## Will fail job if script returns non 0 exit code
##  $1 -> Name of config script line to find
command_runscript() {
    ALLOWED_SCRIPTS=( PRE_SCRIPT SUCCESS_SCRIPT FAILED_SCRIPT FINAL_SCRIPT )
    array_contains ALLOWED_SCRIPTS $1
    FOUND_SCPT=$?
    if [[ $FOUND_SCPT -eq 0 && ! -z ${CONFIG[$1]} ]]; then
        log_entry "| Running $1: ${CONFIG[$1]}"
        SCRIPT_OUT=$( ${CONFIG[$1]} | tee -a $LOG_FILE )
        SCRIPT_RET=${PIPESTATUS[0]}
        if [[ $SCRIPT_RET -ne 0 ]]; then
            log_entry "| Script returned exit code: $SCRIPT_RET"
            # Send notify email about script failure
            mailer "${CONFIG[NOTIFY_EMAIL]}" "cfgbackup job '${CONF_NAME}' failed running $1" "The $1 ( ${CONFIG[$1]} ) for job '${CONF_NAME}' failed with exit code ${SCRIPT_RET}."
            exit 1
        fi
    fi
}

###############################
## Escape the rsync source path, including the user and host for remote ssh sources
## Output the escaped path
escaped_rsync_source() {
    ESCPATH=$( epath_join ${CONFIG[SOURCE_DIR]} )
    source_is_remote
    if [[ $? == 0 ]]; then
        local COLON_IDX=$( substr_index "${CONFIG[SOURCE_DIR]}" ":" )+1
        local SSH_CONNECT=${CONFIG[SOURCE_DIR]:0:$COLON_IDX}
        local SSH_SOURCE=${CONFIG[SOURCE_DIR]:1+$COLON_IDX}
        ESCPATH="${SSH_CONNECT}:\"$( epath_join "$SSH_SOURCE" )\""
    fi
    echo "$ESCPATH"
}

###############################
## Run a sync job
runjob_sync() {
    echo $$ > $PID_FULL
    log_entry "| Job type: sync"
    SYNC_FROM=$( escaped_rsync_source )

    RSYNC_FLAGS="-av --stats ${CONFIG[RSYNC_FLAGS]}"
    if [[ ${CONFIG[ALLOW_DELETIONS]} == "1" ]]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --del"
    fi
    if [[ ${CONFIG[ALLOW_OVERWRITES]} == "0" ]]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --ignore-existing"
    fi
    # Exclude PID_FILE from being synced
    RSYNC_FLAGS="${RSYNC_FLAGS} --exclude=/${PID_FILE}"

    RSYNC_COMMAND="${CONFIG[RSYNC_PATH]} ${RSYNC_FLAGS} ${SYNC_FROM}/ ${RUN_DIR}/"
    log_entry "| Running rsync: $RSYNC_COMMAND"
    RSYNC_COMMAND="$RSYNC_COMMAND >> ${LOG_FILE} 2>&1"
    eval $RSYNC_COMMAND
    RSYNC_EXIT=$?
    if [[ $RSYNC_EXIT -ne 0 ]]; then
        log_entry "| Rsync command exited with code: $RSYNC_EXIT"
        command_runscript FAILED_SCRIPT
        mailer_rsync_exit $RSYNC_EXIT
    else
        command_runscript SUCCESS_SCRIPT
    fi

    # Update timestamp of target dir to indicate backup time
    touch $SYNC_TO
}

###############################
## Run a rotate job
runjob_rotation() {
    log_entry "| Job type: rotation"
    rotate_start
    NEW_RUNDIR=$?
    echo $$ > $PID_FULL

    RSYNC_FLAGS="-av --stats ${CONFIG[RSYNC_FLAGS]}"
    if [[ ${CONFIG[ALLOW_DELETIONS]} == "1" ]]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --del"
    fi
    if [[ ${CONFIG[ALLOW_OVERWRITES]} == "0" ]]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --ignore-existing"
    fi

    if [[ ${CONFIG[ROTATIONALS_HARD_LINK]} == "1" ]]; then
        # Get previous directory for target of link-dest, or skip if no previous backup dir
        PREV_BACKUP=$( rotate_current_backup )
        if [[ $PREV_BACKUP != "" ]]; then
            log_entry "| Hard linking identical files from: $PREV_BACKUP"
            PREV_BACKUP_PATH=$( epath_join "${CONFIG[TARGET_DIR]}" "$PREV_BACKUP" )
            RSYNC_FLAGS="${RSYNC_FLAGS} --link-dest=${PREV_BACKUP_PATH}"
            # If using old version of rsync (prior to 3.1.0), we must manually link files from
            # the previous backup dir; version 3.1.0 and later works with just the link-dest flag above
            if ! rsync_gte_310; then
                log_entry "| Old version of rsync detected; manual linking required."
                #TODO manual link from prev backups
                echo "FAILURE: cfgbackup does not support rsync less than 3.1.0 at this time when performing rotational hard linking."
                exit 1
            fi
        fi
    fi

    SYNC_FROM=$( escaped_rsync_source )
    RSYNC_COMMAND="${CONFIG[RSYNC_PATH]} ${RSYNC_FLAGS} ${SYNC_FROM}/ ${RUN_DIR}/"
    log_entry "| Running rsync: $RSYNC_COMMAND"
    RSYNC_COMMAND="$RSYNC_COMMAND >> ${LOG_FILE} 2>&1"
    eval $RSYNC_COMMAND
    RSYNC_EXIT=$?
    # Check for exit 24 and ignore
    if [[ $RSYNC_EXIT -eq 24 ]]; then
        RSYNC_EXIT=0
    fi
    # On any error, send email report
    if [[ $RSYNC_EXIT -gt 0 ]]; then
        log_entry "| Rsync command exited with code: $RSYNC_EXIT"
        command_runscript FAILED_SCRIPT
        mailer_rsync_exit $RSYNC_EXIT
        return
    else
        command_runscript SUCCESS_SCRIPT
    fi

    # If ALLOW_DELETIONS or ALLOW_OVERWRITES is 0, check for skipped files
    if [[ ${CONFIG[ALLOW_DELETIONS]} == "0" || ${CONFIG[ALLOW_OVERWRITES]} == "0" ]]; then
        runjob_skipped_files
    fi

    # Update timestamp of target dir to indicate backup time
    touch $RUN_DIR

    rotate_complete
}

###############################
## Generate an email report of skipped files, and log them as well
runjob_skipped_files() {
    RSYNC_FLAGS="-ai --dry-run --existing ${CONFIG[RSYNC_FLAGS]}"
    if [[ ${CONFIG[ALLOW_DELETIONS]} == "0" ]]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --del"
    fi
    if [[ ${CONFIG[ALLOW_OVERWRITES]} == "1" ]]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --ignore-existing"
    fi
    # Exclude PID_FILE from being synced
    if [[ ${CONFIG[BACKUP_TYPE]} == "sync" ]]; then
        RSYNC_FLAGS="${RSYNC_FLAGS} --exclude=/${PID_FILE}"
    fi

    RSYNC_COMMAND="${CONFIG[RSYNC_PATH]} ${RSYNC_FLAGS} ${SYNC_FROM}/ ${RUN_DIR}/"
    log_entry "| Checking for skipped files..."
    log_entry "| Running rsync: $RSYNC_COMMAND"
    SKIP_RESULTS=$( $RSYNC_COMMAND | tee -a $LOG_FILE 2>&1 )
    RSYNC_EXIT=${PIPESTATUS[0]}
    SKIP_COUNT=$( echo "$SKIP_RESULTS" | wc -l )

    # On any error, send email report
    if [[ $RSYNC_EXIT -gt 0 ]]; then
        log_entry "| Rsync command exited with code: $RSYNC_EXIT"
    fi

    if [[ $SKIP_COUNT -gt 5000 ]]; then
        # If number of skipped files is too large, just list a summary count
        SKIP_RESULTS="
Skipped ${SKIP_COUNT} files from being altered based off limitations set in the '${CONF_FILE_BASE}' config file.

For specifics, see the log file at:
  ${LOG_FILE}"
    elif [[ $SKIP_COUNT -gt 0 ]]; then
        # Send list of skipped files in the email
        SKIP_RESULTS="
Skipped ${SKIP_COUNT} files from being altered based off limitations set in the '${CONF_FILE_BASE}' config file.

$SKIP_RESULTS
"
    fi

    # If any files were skipped, send an email report
    if [[ ${CONFIG[NOTIFY_EMAIL]} != "" ]]; then
        mailer "${CONFIG[NOTIFY_EMAIL]}" "cfgbackup job '${CONF_NAME}' skipped some files" "$SKIP_RESULTS"
    fi
}


