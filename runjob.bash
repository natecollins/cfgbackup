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
    echo $$ > $PID_FULL
    log_entry "JOB STARTED:  $( date +%Y-%m-%d\ %H:%M:%S )"
    if [[ ${CONFIG[BACKUP_TYPE]} == "rotation" ]]; then
        runjob_rotation()
    elif [[ ${CONFIG[BACKUP_TYPE]} == "sync" ]]; then
        runjob_sync()
    fi
    command_end()
}

###############################
## End job and clean up the pid file
command_end() {
    log_entry "JOB ENDED: $( date +%Y-%m-%d\ %H:%M:%S )"
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
## Run a sync job
runjob_sync() {
    log_entry "| Job type: sync"
    SYNC_FROM=$( epath_join ${CONFIG[SOURCE_DIR]} )
    SYNC_TO=$( epath_join ${CONFIG[TARGET_DIR]} )

    RSYNC_FLAGS="${CONFIG[RSYNC_FLAGS]}"
    # Exclude PID_FILE from being synced
    RSYNC_FLAGS="${RSYNC_FLAGS} --exclude=/${PID_FILE}"

    #TODO rsync command and exit code check

    # Update timestamp of target dir to indicate backup time
    touch $SYNC_TO
}

###############################
## Run a rotate job
runjob_rotatation() {
    log_entry "| Job type: rotation"
    rotate_start
    NEW_RUNDIR=$?

    RSYNC_FLAGS="${CONFIG[RSYNC_FLAGS]}"

    if [[ ${CONFIG[ROTATIONALS_HARD_LINK]} == "1" ]]; then
        # Get previous directory for target of link-dest, or skip if no previous backup dir
        PREV_BACKUP=$( rotate_current_backup )
        if [[ $PREV_BACKUP != "" ]]; then
            RSYNC_FLAGS="${RSYNC_FLAGS} --link-dest=${PREV_BACKUP}"
            # If using old version of rsync (prior to 3.1.0), we must manually link files from
            # the previous backup dir; version 3.1.0 and later works with just the link-dest flag above
            if ! rsync_gte_310; then
                #TODO manual link from prev backups
            fi
        fi
    fi

    #TODO rsync command and exit code check

    # Update timestamp of target dir to indicate backup time
    touch $RUN_DIR

    rotate_complete
}

