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
    echo $$ > $PID_FILE
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
    rm $PID_FILE
}

###############################
## Run a sync job
runjob_sync() {
    return 1
}

###############################
## Run a rotate job
runjob_rotatation() {
    rotate_start()

    #TODO

    rotate_complete()
}

