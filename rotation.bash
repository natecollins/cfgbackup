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
## Ordered by newest backups first, with active/aborted dirs considered newest
## If number of backups exceeds MAX_ROTATIONS, only gets MAX_ROTATIONS directories
## Sets the results in the array: BACKUP_ROTATION_DIRS
rotate_get_dirs() {
    declare -g -a BACKUP_ROTATION_DIRS
    readarray BACKUP_ROTATION_DIRS < <( ls -1 ${CONFIG[TARGET_DIR]} | sort -V )
    array_contains BACKUP_ROTATION_DIRS ${CONFIG[RUNNING_DIRNAME]}
    RUN_DIR=$?
    array_contains BACKUP_ROTATION_DIRS ${CONFIG[ABORTED_DIRNAME]}
    ABT_DIR=$?
    #
    #TODO
}

###############################
## Return the number of backups in target directory, including running/aborted
## If number of backups exceeds MAX_ROTATIONS, returns MAX_ROTATIONS instead
rotate_backup_count() {
    return 0
}

###############################
## Outputs the name of the oldest backup directory that is not older than MAX_ROTATIONS
## If a running/aborted backup exists, that directory is output instead
rotate_oldest_backup() {
    echo "TODO"
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

