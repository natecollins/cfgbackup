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

    # Number of backups
    BACKUP_COUNT=$( rotate_backup_count )
    echo "Backups:              $BACKUP_COUNT / ${CONFIG[MAX_ROTATIONS]}"

    # List current backups
    #TODO backup-running  (failed)          2017-01-16 15:23
    #TODO backup-001                        2017-01-21 16:45
    #TODO backup-002                        2017-01-20 16:43
    #TODO backup-003                        2017-01-19 16:39
    #TODO backup-004                        2017-01-18 16:44
    #TODO etc...
    # List past-rotation directories
    #TODO backup-009                        2016-12-30 16:33
    #TODO backup-010                        2016-12-29 16:34
}

