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
    return 1
}

###############################
## Check if the backup did not complete, but exited cleanly
## Returns 0 if running directory exists and there is no pid file; 1 otherwise
status_is_failed() {
    return 1
}

###############################
## Check if the backup did not complete and exited uncleanly
## Returns 0 if running directory exists and pid file exists without any matching process for that pid; 1 otherwise
status_is_dead() {
    return 1
}

###############################
## Run status report
command_status() {
    return 1
}

