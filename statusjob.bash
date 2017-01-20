###############################
# Status of Config Job
###############################

###############################
## Check if the config is not busy
## Returns 1 if running, failed, or has uncleanly died, 0 otherwise
status_is_ready() {
    if status_is_running || status_is_failed || status_is_dead; then
        return 1
    fi
    return 0
}

###############################
## Check if the config is busy
## Returns 0 if running, failed, or has uncleanly died, 1 otherwise
status_is_busy() {
    if status_is_running || status_is_failed || status_is_dead; then
        return 0
    fi
    return 1
}

###############################
## Check if the backup is successfully running
## Returns 0 if job is running and a pid file exists and a process with matching pid exists, 1 otherwise
status_is_running() {
    if [[ -d $RUN_DIR && -f $PID_FILE ]]; then
        PID=$( cat PID_FILE )
        ps -p $PID > /dev/null
        PID_FOUND=$?
        if [[ $PID_FOUND -eq 0 ]]; then
            return 0
        fi
    fi
    return 1
}

###############################
## Check if the backup did not complete and exited uncleanly
## Returns 0 if running directory exists and pid file exists without any matching process for that pid; 1 otherwise
status_is_dead() {
    if [[ -d $RUN_DIR && -f $PID_FILE ]]; then
        PID=$( cat PID_FILE )
        ps -p $PID > /dev/null
        PID_FOUND=$?
        if [[ $PID_FOUND -ne 0 ]]; then
            return 0
        fi
    fi
    return 1
}

###############################
## Check if the backup did not complete, but exited cleanly
## Returns 0 if running directory exists and there is no pid file; 1 otherwise
status_is_failed() {
    if [[ -d $RUN_DIR && ! -f $PID_FILE ]]; then
        return 0;
    fi
    return 1
}

###############################
## Run status report
command_status() {
    CONFIG_STAT="idle"
    if status_is_running; then
        CONFIG_STAT="running"
    elif status_is_failed; then
        CONFIG_FILE="failed - see log"
    elif status_is_dead; then
        CONFIG_FILE="process died uncleanly"
    fi

    JOB_STARTED="-"
    if [[ -f $PID_FILE ]]; then
        JOB_STARTED=$( date -r $PID_FILE +%Y-%m-%d\ %H:%M:%S )
    fi
    PID_NUM="-"
    if status_is_running; then
        PID_NUM=$( cat $PID_FILE )
    fi

    echo "======= cfgbackup job status ======="
    echo "Config:               $CONFIG_FILE"
    echo "Status:               $CONFIG_STAT"
    echo "Started:              $JOB_STARTED"
    echo "Process ID:           $PID_NUM"
}

