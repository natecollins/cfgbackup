#!/bin/bash

# unit testing for function: rotate_get_dirs

test_pre() {
    declare -g CFG_BACKUP_TYPE=rotation
    declare -g CFG_ROTATE_SUBDIR=backup-DATE
    declare -g CFG_TARGET_DIR=$( mktemp -d )
    declare -g CFG_SORT_PATH=sort
    declare -g CFG_RUNNING_DIRNAME=backup-running
    declare -g CFG_MAX_ROTATIONS=6
}

test_run() {
    # Test 1
    mkdir "${CFG_TARGET_DIR}/backup-20200313"
    mkdir "${CFG_TARGET_DIR}/backup-20200313.1"
    mkdir "${CFG_TARGET_DIR}/backup-20200526"
    mkdir "${CFG_TARGET_DIR}/backup-20230228"
    mkdir "${CFG_TARGET_DIR}/backup-running"

    rotate_get_dirs

    [[ "${BACKUP_ROTATION_DIRS[-1]}" == "backup-20200313" ]] ||
        (msg "oldest dir incorrect: ${BACKUP_ROTATION_DIRS[-1]} != backup-20200313" && return 1)
    [[ "${#BACKUP_ROTATION_XDIRS[@]}" -eq 0 ]] ||
        (msg "extra rotation dir count is not 0: ${#BACKUP_ROTATION_XDIRS[@]}" && return 1)
}

test_post() {
    rm -r "${CFG_TARGET_DIR}"
}
