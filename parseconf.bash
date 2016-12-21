###############################
# Parse Config File
###############################

###############################
## Creates an array of config variables with default values
default_config() {
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
    CONFIG[ROTATIONALS_HARD_LINK]=0
    CONFIG[IDENTICALS_HARD_LINK]=0
    CONFIG[PRE_SCRIPT]=
    CONFIG[SUCCESS_SCRIPT]=
    CONFIG[FAILED_SCRIPT]=
    CONFIG[FINAL_SCRIPT]=
}

###############################
## Parse config file given
## Returns 0 on success, 1 on error
## Any errors will be in PARSE_ERRORS
parse_config() {
    declare -a PARSE_ERRORS
    default_config

    # Verify config file exists and is readable
    #TODO

    # Parse config file for variables
    #TODO
        # Record unknown variables as errors
        #TODO
        # Record any line that is not a variable/comment or blank as an error
        #TODO
        # Set known variables into CONFIG array
        #TODO

    # Ensure SOURCE_DIR, TARGET_DIR, and BACKUP_TYPE are set
    #TODO

    if [[ ${#PARSE_ERRORS[@]} -ne 0 ]]; then
        return 1
    fi
    return 0
}

