###############################
# Logging functions
###############################

###############################
## Check if log directory is writable
## Return 0 if writable
log_can_write() {
    [[ -d ${CONFIG[LOG_DIR]} && -w ${CONFIG[LOG_DIR]} ]]
    return $?
}

###############################
## Initialize log
## Return 0 on success
log_init() {
    CONF_FILE_BASE=$( basename $CONFIG_FILE )
    CONF_NAME=${CONF_FILE_BASE%.*}
    # Ensure dir has trailing slash
    CONFIG[LOG_DIR]=${CONFIG[LOG_DIR]%/}/
    # Substitution for placeholders
    CONFIG[LOG_FILENAME]=${CONFIG[LOG_FILENAME]//CONFNAME/$CONF_NAME}
    CONFIG[LOG_FILENAME]=${CONFIG[LOG_FILENAME]//DATE/$(date +%Y%m%d)}
    CONFIG[LOG_FILENAME]=${CONFIG[LOG_FILENAME]//TIME/$(date +%H%M%S)}
    # Test access to file
    declare -g LOG_FILE
    LOG_FILE=$( epath_join ${CONFIG[LOG_DIR]} ${CONFIG[LOG_FILENAME]} )
    return $( log_can_write )
}

###############################
## Create a logfile entry
##  $1 -> Log message entry
log_entry() {
    echo "$1" >> $LOG_FILE
}

###############################
## Get name of most recent log file for current config
## Prints escaped full path of file
log_last_file() {
    echo "TODO"
}

