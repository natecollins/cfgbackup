###############################
# Parse Config File
###############################

###############################
## Creates an array of config variables with default values
default_config() {
    declare -g -A CONFIG
    CONFIG[LOG_DIR]=/var/log/cfgbackup/
    CONFIG[LOG_FILENAME]=cfgbackup_DATETIME.log
    CONFIG[SOURCE_DIR]=
    CONFIG[TARGET_DIR]=
    CONFIG[RSYNC_FLAGS]=
    CONFIG[BACKUP_TYPE]=
    CONFIG[SUBDIR_NAME]=backup-NUM1
    CONFIG[RUNNING_DIRNAME]=backup-running
    CONFIG[ABORTED_DIRNAME]=backup-aborted
    CONFIG[ALLOW_DELETIONS]=1
    CONFIG[ALLOW_OVERWRITES]=1
    CONFIG[MAX_ROTATIONS]=
    CONFIG[ROTATIONALS_HARD_LINK]=0
    CONFIG[IDENTICALS_HARD_LINK]=0
    CONFIG[PRE_SCRIPT]=
    CONFIG[SUCCESS_SCRIPT]=
    CONFIG[FAILED_SCRIPT]=
    CONFIG[FINAL_SCRIPT]=
}

###############################
## Parse a value for a given config line
##  $1 -> File to search
##  $2 -> Name of parameter to get value for
## Prints the string value, or empty string if not found
config_param_get() {
    grep -E "^ *$2 *=" $1 | tail -n 1 | cut -d= -f2- | sed 's/ *$//' | sed 's/^ *//'
}

###############################
## Parse config file given
## Returns 0 on success, 1 on error
## Any errors will be in PARSE_ERRORS
parse_config() {
    declare -g -a PARSE_ERRORS
    default_config
    CONFIG_FILE=$1

    # Verify config file exists and is readable
    if [[ ! -f $CONFIG_FILE || ! -r $CONFIG_FILE ]]; then
        PARSE_ERRORS+=("Config file doesn't exist or isn't readable.")
    else
        # Parse config file for variables
        for KEY in "${!CONFIG[@]}"; do
            # Get variable values from config file
            CONFIG_VALUE=$(config_param_get $CONFIG_FILE $KEY)
            # If value is empty, leave as default
            if [[ $CONFIG_VALUE == "" ]]; then
                CONFIG_VALUE=${CONFIG[$KEY]}
            fi
            # Update CONFIG values
            CONFIG[$KEY]=$CONFIG_VALUE
        done

        # Ensure SOURCE_DIR, TARGET_DIR, and BACKUP_TYPE are set
        if [[ ${CONFIG[SOURCE_DIR]} == "" ]]; then
            PARSE_ERRORS+=("Missing required value for SOURCE_DIR.")
        fi
        if [[ ${CONFIG[TARGET_DIR]} == "" ]]; then
            PARSE_ERRORS+=("Missing required value for TARGET_DIR.")
        fi
        if [[ ${CONFIG[BACKUP_TYPE]} == "" ]]; then
            PARSE_ERRORS+=("Missing required value for BACKUP_TYPE.")
        fi
        if [[ ${CONFIG[BACKUP_TYPE]} == "rotation" && ( ! ${CONFIG[MAX_ROTATIONS]} =~ ^[0-9]+$ || ${CONFIG[MAX_ROTATIONS]} -lt 1 ) ]]; then
            PARSE_ERRORS+=("Value of MAX_ROTATIONS must be a positive integer for rotation backups.")
        fi
    fi

    if [[ ${#PARSE_ERRORS[@]} -ne 0 ]]; then
        return 1
    fi
    return 0
}

