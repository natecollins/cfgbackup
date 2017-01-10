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
## If a running/aborted backup exists, that directory is output instead
rotate_oldest_backup() {
    local BACKUP_COUNT=$( rotate_backup_count )
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        echo ${BACKUP_ROTATION_DIRS[-1]}
    fi
}

###############################
## Create/rename directory to begin new backup
## Returns 0 on success, 1 on running dir already exists, 2 on other error
rotate_start() {
    return 1
}

###############################
## Rotate directories after backup completes and rename running directory
rotate_complete() {
    return 1
}

###############################
## Attempt to stop active job and rename running directory
rotate_abort() {
    return 1
}

