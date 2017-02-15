###############################
# List Backups of Config Job
###############################

###############################
## Run list report
command_list() {
    # On sync job, report and exit
    if [[ ${CONFIG[BACKUP_TYPE]} != "rotation" ]]; then
        echo "Job '${CONF_NAME}' is a sync job. Backup lists only exist for rotation jobs."
        return
    fi

    rotate_get_dirs

    # Number of backups
    BACKUP_COUNT=$( rotate_backup_count )
    echo "Backups:  $BACKUP_COUNT / ${CONFIG[MAX_ROTATIONS]}"
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        echo "------------------------------------------------------------"
    fi

    # List current backups
    for SDIR in "${BACKUP_ROTATION_DIRS[@]}"; do
        SDIR_FULL=$( epath_join "${CONFIG[TARGET_DIR]}" "$SDIR" )
        SDIR_STATE=""
        if [[ $SDIR_FULL == $RUN_DIR ]]; then
            if status_is_running; then
                SDIR_STATE="running"
            elif status_is_dead; then
                SDIR_STATE="dead"
            elif status_is_failed; then
                SDIR_STATE="failed"
            fi
            SDIR_STATE="(${SDIR_STATE})"
        fi
        SDIR_MTIME=$( date +%Y-%m-%d\ %H:%M -r $SDIR_FULL )
        printf '%-44s' "${SDIR%[[:space:]]}  $SDIR_STATE"
        printf '%s' "$SDIR_MTIME"
        echo
    done
    # List past-rotation directories
    if [[ ${#BACKUP_ROTATION_XDIRS[@]} -gt 0 ]]; then
        printf '%s' "------------- Backups Past Rotation Max ("
        PAST_NUM="${#BACKUP_ROTATION_XDIRS[@]}) -"
        PAST_PAD="------------------"
        printf '%s' "$PAST_NUM"
        printf '%*.*s' 0 $(( 19 - ${#PAST_NUM} )) "$PAST_PAD"
        echo
    fi
    for SDIR in "${BACKUP_ROTATION_XDIRS[@]}"; do
        SDIR_FULL=$( epath_join "${CONFIG[TARGET_DIR]}" "$SDIR" )
        SDIR_MTIME=$( date +%Y-%m-%d\ %H:%M -r $SDIR_FULL )
        printf '%-44s' "${SDIR%[[:space:]]}"
        printf '%s' "$SDIR_MTIME"
        echo
    done
}

