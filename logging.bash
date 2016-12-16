###############################
# Logging functions
###############################

###############################
## Check if log directory is writable
## Return 0 if writable
log_can_write() {
    [[ -d $CONFIG[LOG_DIR] && -w $CONFIG[LOG_DIR] ]]
    return $?
}


###############################
## Initialize log
## Return 0 on success
log_init() {
    # Ensure dir has trailing slash
    $CONFIG[LOG_DIR]=${CONFIG[LOG_DIR]%/}/
    # Substitution for DATE and TIME
    $CONFIG[LOG_FILENAME]=${CONFIG[LOG_FILENAME]//DATE/$(date +%Y%m%d)}
    $CONFIG[LOG_FILENAME]=${CONFIG[LOG_FILENAME]//TIME/$(date +%H%M%S)}
    # Test access to file
    touch ${CONFIG[LOG_DIR]}${CONFIG[LOG_FILENAME]} 2> /dev/null
    echo $?
}

###############################
## Create a logfile entry
##  $1 -> Log message entry
log_entry() {
    #TODO
    return 1
}


