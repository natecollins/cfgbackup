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
    log_entry "=============================="
    log_entry "JOB STARTED:  $( date +%Y-%m-%d\ %H:%M:%S )"

    #TODO

    log_entry "JOB FINISHED: $( date +%Y-%m-%d\ %H:%M:%S )"
    # Cleanup by removing cfgbackup.pid file
    rm $PID_FILE
}

