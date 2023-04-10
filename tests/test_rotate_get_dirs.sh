#!/bin/bash

# unit testing for function: rotate_get_dirs

test_pre() {
    declare -A -g CONFIG
    CONFIG[BACKUP_TYPE]=rotation
    CONFIG[ROTATE_SUBDIR]=backup-DATE
    CONFIG[TARGET_DIR]=$( mktemp -d )
    CONFIG[SORT_PATH]=sort
    CONFIG[RUNNING_DIRNAME]=backup-running
    CONFIG[MAX_ROTATIONS]=6
}

test_run() {
    # Test 1
    mkdir "${CONFIG[TARGET_DIR]}/backup-20200313"
    mkdir "${CONFIG[TARGET_DIR]}/backup-20200313.1"
    mkdir "${CONFIG[TARGET_DIR]}/backup-20200526"
    mkdir "${CONFIG[TARGET_DIR]}/backup-20230228"
    mkdir "${CONFIG[TARGET_DIR]}/backup-running"

    rotate_get_dirs

    [[ "${BACKUP_ROTATION_DIRS[-1]}" == "backup-20200313" ]] ||
        (msg "oldest dir incorrect: ${BACKUP_ROTATION_DIRS[-1]} != backup-20200313" && return 1)
    [[ "${#BACKUP_ROTATION_XDIRS[@]}" -eq 0 ]] ||
        (msg "extra rotation dir count is not 0: ${#BACKUP_ROTATION_XDIRS[@]}" && return 1)
}

test_post() {
    rm -r "${CONFIG[TARGET_DIR]}"
}
