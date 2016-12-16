###############################
# Verify Config File Settings
###############################

###############################
## Run checks on config and access
command_check() {
    # Test log access
    log_can_write
    if [[ $? != 0 ]]; then
        echo "ERROR: Cannot write to log directory ${CONFIG[LOG_DIR]}"
        exit 1
    fi

    # Test source access
    #TODO

    # Test target access
    #TODO

    # If scripts specified, test scripts are readable/execuatable
    #TODO

    echo "Config is OK."
    exit 0
}

