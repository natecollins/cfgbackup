###############################
# Rotation Functions
###############################

###############################
## Check if a backup running directory exists in the target directory
## Returns 0 if RUNNING_DIRNAME exists, 1 otherwise
rotate_backup_running() {
    CHECK_RUN=$( path_join "${CONFIG[TARGET_DIR]}" "${CONFIG[RUNNING_DIRNAME]}" )
    if [[ -d $CHECK_RUN ]]; then
        return 0
    fi
    return 1
}

###############################
## Check if a backup aborted directory exists in the target directory
## Returns 0 if ABORTED_DIRNAME exists, 1 otherwise
rotate_backup_aborted() {
    CHECK_ABT=$( path_join "${CONFIG[TARGET_DIR]}" "${CONFIG[ABORTED_DIRNAME]}" )
    if [[ -d $CHECK_ABT ]]; then
        return 0
    fi
    return 1
}

###############################
## Check if it is safe to start a new backup rotation
## Returns 0 if no running or aborted backups exist, 1 otherwise
rotate_is_ready() {
    if rotate_backup_running || rotate_backup_aborted; then
        return 1
    fi
    return 0
}

###############################
## Get list of current backup directories, including active and aborted dirs
## Ordered by newest backups first, with running/aborted dirs considered newest
## If number of backups exceeds MAX_ROTATIONS, only gets MAX_ROTATIONS directories
## Sets the results in the array: BACKUP_ROTATION_DIRS
rotate_get_dirs() {
    declare -g -a BACKUP_ROTATION_DIRS
    readarray BACKUP_ROTATION_DIRS < <( ls -1 ${CONFIG[TARGET_DIR]} | sort -V )
    # Ensure running and aborted dirs are listed first
    RUN_IDX=$( array_value_index BACKUP_ROTATION_DIRS ${CONFIG[RUNNING_DIRNAME]} )
    if [[ $RUN_IDX != "-1" ]]; then
        unset BACKUP_ROTATION_DIRS[$RUN_IDX]
        BACKUP_ROTATION_DIRS=( ${CONFIG_FILE[RUNNING_DIRNAME]} "${BACKUP_ROTATION_DIRS[@]}" )
    fi
    ABT_IDX=$( array_value_index BACKUP_ROTATION_DIRS ${CONFIG[ABORTED_DIRNAME]} )
    if [[ $ABT_IDX != "-1" ]]; then
        unset BACKUP_ROTATION_DIRS[$ABT_IDX]
        BACKUP_ROTATION_DIRS=( ${CONFIG_FILE[ABORTED_DIRNAME]} "${BACKUP_ROTATION_DIRS[@]}" )
    fi
    # Limit to MAX_ROTATIONS
    BACKUP_ROTATION_DIRS=${BACKUP_ROTATION_DIRS[@]:0:${CONFIG[MAX_ROTATIONS]}}
}

###############################
## Print the number of backups in target directory, including running/aborted
## If number of backups exceeds MAX_ROTATIONS, returns MAX_ROTATIONS instead
rotate_backup_count() {
    rotate_get_dirs
    print ${#BACKUP_ROTATION_DIRS[@]}
}

###############################
## Outputs the name of the oldest backup directory that is not older than MAX_ROTATIONS
rotate_oldest_backup() {
    local BACKUP_COUNT=$( rotate_backup_count )
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        echo ${BACKUP_ROTATION_DIRS[-1]}
    fi
}

###############################
## Create/rename directory to begin new backup
## Exits script with code 1 on failure
rotate_start() {
    rotate_backup_count
    ROT_COUNT=$?
    # Check for abort directory
    if [[ ${BACKUP_ROTATION_DIRS[0]} == ${CONFIG[ABORTED_DIRNAME]} || \
          ${BACKUP_ROTATION_DIRS[1]} == ${CONFIG[ABORTED_DIRNAME]} ]]; then
        echo "ERROR: Aborted backup directory exists: ${CONFIG[ABORTED_DIRNAME]}"
        exit 1
    fi
    # Check for active directory
    if [[ ${BACKUP_ROTATION_DIRS[0]} == ${CONFIG[RUNNING_DIRNAME]} || \
          ${BACKUP_ROTATION_DIRS[1]} == ${CONFIG[RUNNING_DIRNAME]} ]]; then
        echo "ERROR: Running backup directory already exists: ${CONFIG[RUNNING_DIRNAME]}"
        exit 1
    fi

    # Check if at rotation max
    RUN_DIR=$( epath_join ${CONFIG[TARGET_DIR]} ${CONFIG_FILE[RUNNING_DIRNAME]} )
    if [[ $ROT_COUNT -eq ${COUNT[MAX_ROTATIONS]} ]]; then
        # Rename oldest directory for run
        OLDEST_DIR=$( rotate_oldest_backup )
        if [[ $OLDEST_DIR != "" ]]; then
            PREV_DIR=$( epath_join ${CONFIG[TARGET_DIR]} ${OLDEST_DIR} )
            mv $PREV_DIR $RUN_DIR
            if [[ $? -ne 0 ]]; then
                echo "ERROR: Could not rotate directory: ${OLDEST_DIR}"
                exit 1
            fi
        else
            # One of those "shouldn't be possible" situations
            echo "ERROR: Failed to find old directory to rotate."
            exit 1
        fi
    else
        # Create new directory for run
        mkdir $RUN_DIR
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Could not create new rotate directory: ${OLDEST_DIR}"
            exit 1
        fi
    fi
}

###############################
## Rotate directories after backup completes and rename running directory
rotate_complete() {
    MATCH_NUM0=$( substr_index "${CONFIG[SUBDIR_NAME]}" "NUM0" )
    MATCH_DATE=$( substr_index "${CONFIG[SUBDIR_NAME]}" "DATE" )
    if [[ $MATCH_DATE != "-1" ]]; then
        rotate_complete_date
    elif [[ $MATCH_NUM0 != "-1" ]]; then
        rotate_complete_num "0"
    else
        rotate_complete_num "1"
    fi
}

rotate_complete_date() {
    TODAY=$( date +%Y%m%d )
    COMPL_SUB=${CONFIG[SUBDIR_NAME]/DATE/$TODAY}
    COMPL_DIR=$( epath_join ${CONFIG[TARGET_DIR]} ${COMPL_SUB} )
    COMPL_EXT=0
    # Check if complete dir already exists (with some sanity limits)
    while [[ -d $COMPL_DIR && $COMPL_EXT -lt 1000 ]]; do
        # If exists, append .1, .2, .3, etc to complete dir
        COMPL_EXT=$(( COMPL_EXT + 1 ))
        COMPL_DIR=$( epath_join ${CONFIG[TARGET_DIR]} "${COMPL_SUB}.${COMPL_EXT}" )
    done
    # Too many backups!
    if [[ $COMPL_EXT -gt 999 ]]; then
        echo "ERROR: Too many backups for single date (Max of 999): ${TODAY}"
        rotate_abort
    fi
    # Rename to complete dir
    RUN_DIR=$( epath_join ${CONFIG[TARGET_DIR]} ${CONFIG_FILE[RUNNING_DIRNAME]} )
    mv $RUN_DIR $COMPL_DIR
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not rename completed backup to: ${COMPL_DIR}"
        exit 1
    fi
}

rotate_complete_num() {
    return 1
}

###############################
## Attempt to stop active job and rename running directory
rotate_abort() {
    return 1
}

###############################
## Reset aborted backup directory for use again
rotate_reset_abort() {
    return 1
}

