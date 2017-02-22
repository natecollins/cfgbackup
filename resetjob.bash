#######################################
# RESET COMMAND
#######################################

###############################
## Reset a failed job back to a ready state
## Returns 0 on reset ready, 1 on reset canceled
reset_makeready() {
    if [[ $- == *i* ]] && status_is_running; then
        read -p "The $CONF_NAME job is currently running. Do you want to kill it? [y/N] " -n 1
        echo
        if [[ $REPLY == "y" ]]; then
            reset_killjob
        else
            echo "Leaving job running."
            return 1
        fi
    fi
    reset_killjob
    return 0
}

###############################
## Attempt to kill the currently running job; does nothing if no job if running
## Ends script with exit code 1 if a job is still running after kill attempt
reset_killjob() {
    if status_is_running; then
        PID=$( cat $PID_FULL )
        echo "Killing $CONF_NAME backup job, pid ${PID}..."
        kill $PID
        sleep 3
        if status_is_running; then
            echo "Job is still alive; hiring better assassins..."
            kill -9 $PID
            sleep 2
        fi
        if status_is_running; then
            echo "ERROR: Could not kill job for $CONF_NAME"
            exit 1
        fi
    fi
}

###############################
## Attempt to remove the pid file; does nothing if no pid file exists
## Ends script with exit code 1 if pid file exists and could not be deleted
reset_rmpidfile() {
    if [[ -f $PID_FULL ]]; then
        rm $PID_FULL
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Could not remove pid file $PID_FULL"
            exit 1
        fi
    fi
}

###############################
## Attempt to move the running directory back to the oldest rotational directory name
## Does nothing for sync jobs
## For rotations using DATE subdir names, the dir name may not be what it was previously
reset_mvrundir() {
    if [[ ${CONFIG[BACKUP_TYPE]} == "rotation" ]]; then
        rotate_get_dirs
        if [[ ! -d $RUN_DIR || ${#BACKUP_ROTATION_DIRS[@]} -lt 1 ]]; then
            return
        fi
        rotate_reset
    fi
}

###############################
## For interactive terminals, get confirmation before killing a runnning job
command_reset() {
    if status_is_ready; then
        echo "Job '$CONF_NAME' is ready and does not need to be reset."
        exit 0
    fi

    if ! reset_makeready; then
        return
    fi
    reset_rmpidfile
    reset_mvrundir

    if status_is_ready; then
        echo "Job '$CONF_NAME' has been reset successfully."
    else
        echo "Job reset for '$CONF_NAME' failed!"
        exit 1
    fi
}

