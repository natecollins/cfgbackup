###############################
# Run Config Backup Job
###############################

###############################
## Run backup job
command_run() {
    if status_is_busy; then
        echo "ERROR: Cannot start new backup job if previous job is not completed."
        exit 1
    fi

    # Record run pid in target dir cfgbackup.pid file
    log_entry "JOB STARTED:  $( date +%Y-%m-%d\ %H:%M:%S )"
    if [[ ${CONFIG[BACKUP_TYPE]} == "rotation" ]]; then
        runjob_rotation
    elif [[ ${CONFIG[BACKUP_TYPE]} == "sync" ]]; then
        runjob_sync
    fi
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
## Get what version of rsync are we using
## Outputs the rsync verion number, e.g. 3.1.0
rsync_version() {
    rsync --version | head -n 1 | awk '{ print $3 }'
}

###############################
## Is the rsync version at least 3.1.0
## Returns 0 if version 3.1.0 or greater
rsync_gte_310() {
    RSYNC_VER=$( rsync_version )
    RSYNC_CHECK=$( echo -e "${RSYNC_VER}\n3.1.0" | sort -V | head -n 1 )
    if [[ $RSYNC_CHECK == "3.1.0" ]]; then
        return 0;
    fi
    return 1
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
    # Exclude PID_FILE from being synced
    RSYNC_FLAGS="${RSYNC_FLAGS} --exclude=/${PID_FILE}"

    RSYNC_COMMAND="${CONFIG[RSYNC_PATH]} ${RSYNC_FLAGS} ${SYNC_FROM} ${RUN_DIR} >> ${LOG_FILE} 2>&1"
    eval $RSYNC_COMMAND
    RSYNC_EXIT=$?

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

    if [[ ${CONFIG[ROTATIONALS_HARD_LINK]} == "1" ]]; then
        # Get previous directory for target of link-dest, or skip if no previous backup dir
        PREV_BACKUP=$( rotate_current_backup )
        if [[ $PREV_BACKUP != "" ]]; then
            RSYNC_FLAGS="${RSYNC_FLAGS} --link-dest=${PREV_BACKUP}"
            # If using old version of rsync (prior to 3.1.0), we must manually link files from
            # the previous backup dir; version 3.1.0 and later works with just the link-dest flag above
            if ! rsync_gte_310; then
                #TODO manual link from prev backups
                echo "FAILURE: cfgbackup does not support rsync less than 3.1.0 at this time when performing rotational hard linking."
                exit 1
            fi
        fi
    fi

    SYNC_FROM=$( escaped_rsync_source )
    RSYNC_COMMAND="${CONFIG[RSYNC_PATH]} ${RSYNC_FLAGS} ${SYNC_FROM} ${RUN_DIR} >> ${LOG_FILE} 2>&1"
    eval $RSYNC_COMMAND
    RSYNC_EXIT=$?
    # Check for exit 24 and ignore
    if [[ $RSYNC_EXIT -eq 24 ]]; then
        RSYNC_EXIT=0
    fi
    # On any error, send email report
    if [[ $RSYNC_EXIT -gt 0 ]]; then
        echo "TODO send rsync failure email"
    fi

    # Update timestamp of target dir to indicate backup time
    touch $RUN_DIR

    rotate_complete
}

