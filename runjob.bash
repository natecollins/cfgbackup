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
## Run a sync job
runjob_sync() {
    log_entry "| Job type: sync"
    SYNC_FROM=$( epath_join ${CONFIG[SOURCE_DIR]} )
    SYNC_TO=$( epath_join ${CONFIG[TARGET_DIR]} )

    # Exclude PID_FILE from being synced
    #TODO
}

###############################
## Run a rotate job
runjob_rotatation() {
    log_entry "| Job type: rotation"
    NEW_RUNDIR=$( rotate_start )

    RSYNC_FLAGS="${CONFIG[RSYNC_FLAGS]}"

    if [[ ${CONFIG[ROTATIONALS_HARD_LINK]} == "1" ]]; then
        # Get previous directory for target of link-dest, or skip if no previous backup dir

        # If using old version of rsync (prior to 3.1.0), we must manually link files from
        # the previous backup dir
    fi

    #TODO

    rotate_complete
}

