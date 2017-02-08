###############################
# Verify Config File Settings
###############################

###############################
## Check if source directory is remote
## Return 0 if remote; 1 otherwise
source_is_remote() {
    local COLON_IDX=$( substr_index "${CONFIG[SOURCE_DIR]}" ":" )
    local SLASH_IDX=$( substr_index "${CONFIG[SOURCE_DIR]}" "/" )
    if [[ $COLON_IDX -ge "0" && $COLON_IDX -lt $SLASH_IDX ]]; then
        return 0
    fi
    return 1
}

###############################
## Run checks on config and access
command_check() {
    # Test log access
    log_can_write
    if [[ $? != 0 ]]; then
        echo "ERROR: Cannot write to log directory of ${CONFIG[LOG_DIR]}"
        exit 1
    fi

    # Test source access
    source_is_remote
    if [[ $? == 0 ]]; then
        local COLON_IDX=$( substr_index "${CONFIG[SOURCE_DIR]}" ":" )+1
        local SSH_CONNECT=${CONFIG[SOURCE_DIR]:0:$COLON_IDX}
        local SSH_SOURCE=${CONFIG[SOURCE_DIR]:1+$COLON_IDX}
        # Check SSH connection
        ssh -o BatchMode=yes $SSH_CONNECT exit 0
        if [[ $? != 0 ]]; then
            echo "ERROR: Could not connect via SSH to ${SSH_CONNECT}"
            exit 1
        fi

        # Check remote directory
        ssh -o BatchMode=yes $SSH_CONNECT [[ ! -d $SSH_SOURCE || ! -r $SSH_SOURCE ]]
        if [[ $? != 0 ]]; then
            echo "ERROR: Cannot read from remote source directory of ${SSH_SOURCE}"
            exit 1
        fi
    else
        # Check local directory
        if [[ ! -d ${CONFIG[SOURCE_DIR]} || ! -r ${CONFIG[SOURCE_DIR]} ]]; then
            echo "ERROR: Cannot read from local source directory of ${CONFIG[SOURCE_DIR]}"
            exit 1
        fi
    fi

    # Test target access
    if [[ ! -d ${CONFIG[TARGET_DIR]} || ! -w ${CONFIG[TARGET_DIR]} ]]; then
        echo "ERROR: Cannot write to target directory of ${CONFIG[TARGET_DIR]}"
        exit 1
    fi

    # If scripts specified, test scripts are readable/execuatable
    local CHECK_SCRIPTS=( "${CONFIG[PRE_SCRIPT]}" "${CONFIG[SUCCESS_SCRIPT]}" "${CONFIG[FAILED_SCRIPT]}" "${CONFIG[FINAL_SCRIPT]}" )
    for SCRPT in "${CHECK_SCRIPTS[@]}"; do
        SCRPT1=$( echo $SCRPT | awk '{ print $1; }' )
        if [[ -z ${SCRPT1} ]]; then
            continue;
        fi
        if [[ ! -f ${SCRPT1} || ! -r ${SCRPT1} || ! -x ${SCRPT1} ]]; then
            echo "ERROR: Script is either not accessible or not executable ${SCRPT}"
            exit 1
        fi
    done
}

