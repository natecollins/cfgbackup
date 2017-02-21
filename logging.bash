#######################################
# LOGGING FUNCTIONS
#######################################

###############################
## Check if log directory is writable
## Return 0 if writable
log_can_write() {
    [[ -d ${LOG_DIR} && -w ${LOG_DIR} ]]
    return $?
}

###############################
## Attempt to compress old logs
log_compress() {
    if [[ ${CONFIG[COMPRESS_LOGS]} == "1" ]]; then
        # List files that can match LOG_FILENAME minus exact DATE and TIME variables
        LOG_MATCH=${CONFIG[LOG_FILENAME]//DATE/*}
        LOG_MATCH=${LOG_MATCH//TIME/*}
        LM_PATH=$( epath_join ${CONFIG[LOG_DIR]} )
        # Zip old log files
        ZOUT=$( find $LM_PATH -mindepth 1 -maxdepth 1 -mtime +2 -name "${LOG_MATCH}" -exec ${CONFIG[COMPRESS_PATH]} {} \; 2>&1 )
        ZEXIT=$?
        if [[ $ZEXIT -ne 0 ]]; then
            echo "ERROR: cfgbackup was unable to compress old logs; returned exit code $ZEXIT"
            echo "Output was: $ZOUT"
            exit 1
        fi
    fi
}

###############################
## Initialize log
## Return 0 on success
log_init() {
    CONFIG[LOG_FILENAME]=${CONFIG[LOG_FILENAME]//CONFNAME/$CONF_NAME}
    declare -g LOG_FILE
    declare -g LOG_DIR
    LOG_FILE=${CONFIG[LOG_FILENAME]//DATE/$(date +%Y%m%d)}
    LOG_FILE=${LOG_FILE//TIME/$(date +%H%M%S)}
    LOG_DIR=$( epath_join ${CONFIG[LOG_DIR]} )
    # Join path and escape
    LOG_FILE=$( epath_join ${CONFIG[LOG_DIR]} ${LOG_FILE} )
    # Attempt to create the log directory if it doesn't exist
    mkdir -p $LOG_DIR > /dev/null 2>&1
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
## Prints escaped full path of file, or empty string if no match
log_last_file() {
    # List files that can match LOG_FILENAME minus exact DATE and TIME variables
    LOG_MATCH=${CONFIG[LOG_FILENAME]//DATE/*}
    LOG_MATCH=${LOG_MATCH//TIME/*}
    LM_PATH=$( epath_join ${CONFIG[LOG_DIR]} )
    LM_PATH=$( path_join $LM_PATH $LOG_MATCH )
    # Get list of files
    LASTLOG=( $( ls -1 $LM_PATH 2> /dev/null | tail -n 1 ) )
    # Return last entry
    echo $LASTLOG
}

