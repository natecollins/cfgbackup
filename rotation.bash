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
        BACKUP_ROTATION_DIRS=( ${CONFIG[RUNNING_DIRNAME]} "${BACKUP_ROTATION_DIRS[@]}" )
    fi
    # Limit to MAX_ROTATIONS
    BACKUP_ROTATION_DIRS=( "${BACKUP_ROTATION_DIRS[@]:0:${CONFIG[MAX_ROTATIONS]}}" )
}

###############################
## Print the number of backups in target directory, including running/aborted
## If number of backups exceeds MAX_ROTATIONS, returns MAX_ROTATIONS instead
rotate_backup_count() {
    rotate_get_dirs
    echo ${#BACKUP_ROTATION_DIRS[@]}
}

###############################
## Get the name of the most recent non-running rotation directory
## Outputs the directory name, or nothing if no prior backups exist
rotate_current_backup() {
    BACKUP_COUNT=$( rotate_backup_count )
    RECENT_ROT=
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        if [[ ${BACKUP_ROTATION_DIRS[0]} != ${CONFIG[RUNNING_DIRNAME]} ]]; then
            RECENT_ROT=${BACKUP_ROTATION_DIRS[0]}
        elif [[ $BACKUP_COUNT -gt 1 ]]; then
            RECENT_ROT=${BACKUP_ROTATION_DIRS[1]}
        fi
    fi
    echo "$RECENT_ROT"
}

###############################
## Outputs the name of the oldest backup directory that is not older than MAX_ROTATIONS
rotate_oldest_backup() {
    BACKUP_COUNT=$( rotate_backup_count )
    if [[ $BACKUP_COUNT -gt 0 ]]; then
        echo ${BACKUP_ROTATION_DIRS[-1]}
    fi
}

###############################
## Create/rename directory to begin new backup
## Exits script with code 1 on failure
## Returns 0 on new empty run dir created, returns 1 on re-using oldest backup dir
rotate_start() {
    rotate_get_dirs
    ROT_COUNT=$( rotate_backup_count )
    # Check for active directory
    if [[ ${BACKUP_ROTATION_DIRS[0]} == ${CONFIG[RUNNING_DIRNAME]} ]]; then
        echo "ERROR: Running backup directory already exists: ${CONFIG[RUNNING_DIRNAME]}"
        exit 1
    fi

    # Check if at rotation max
    if [[ $ROT_COUNT -eq ${CONFIG[MAX_ROTATIONS]} ]]; then
        log_entry "| At maximum rotation count of ${CONFIG[MAX_ROTATIONS]}"
        # Rename oldest directory for run
        OLDEST_DIR=$( rotate_oldest_backup )
        if [[ $OLDEST_DIR != "" ]]; then
            log_entry "| Renaming: $OLDEST_DIR => ${CONFIG[RUNNING_DIRNAME]}"
            PREV_DIR=$( epath_join ${CONFIG[TARGET_DIR]} ${OLDEST_DIR} )
            mv $PREV_DIR $RUN_DIR
            if [[ $? -ne 0 ]]; then
                echo "ERROR: Could not rotate directory: ${OLDEST_DIR}"
                exit 1
            fi
            return 1
        else
            # One of those "shouldn't be possible" situations
            echo "ERROR: Failed to find old directory to rotate."
            exit 1
        fi
    else
        log_entry "| Found $ROT_COUNT backups out of a max of ${CONFIG[MAX_ROTATIONS]}"
        log_entry "| Creating new directory: ${CONFIG[RUNNING_DIRNAME]}"
        # Create new directory for run
        mkdir $RUN_DIR
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Could not create new rotate directory: ${OLDEST_DIR}"
            exit 1
        fi
        return 0
    fi
}

###############################
## Rotate directories after backup completes and rename running directory
rotate_complete() {
    MATCH_NUM0=$( substr_index "${CONFIG[ROTATE_SUBDIR]}" "NUM0" )
    MATCH_DATE=$( substr_index "${CONFIG[ROTATE_SUBDIR]}" "DATE" )
    if [[ $MATCH_DATE != "-1" ]]; then
        rotate_complete_date
    elif [[ $MATCH_NUM0 != "-1" ]]; then
        RE0="NUM(0*)0[^01]?"
        RE1="NUM(0+)1"
        if [[ ${CONFIG[ROTATE_SUBDIR]} =~ $RE1 ]]; then
            rotate_complete_num "1" ${#BASH_REMATCH[1]}
        elif [[ ${CONFIG[ROTATE_SUBDIR]} =~ $RE0 ]]; then
            rotate_complete_num "0" ${#BASH_REMATCH[1]}
        else
            echo "ERROR: Unexpected rotate directory variable name"
            exit 1
        fi
    else
        rotate_complete_num "1"
    fi
}

###############################
## Having completed a running backup, rename running directory to a date based directory
rotate_complete_date() {
    TODAY=$( date +%Y%m%d )
    COMPL_SUB=${CONFIG[ROTATE_SUBDIR]/DATE/$TODAY}
    COMPL_DIR=$( epath_join ${CONFIG[TARGET_DIR]} ${COMPL_SUB} )
    COMPL_EXT=0
    # Check if complete dir already exists (with some sanity limits)
    while [[ -d $COMPL_DIR && $COMPL_EXT -le 999 ]]; do
        # If exists, append .1, .2, .3, etc to complete dir
        COMPL_EXT=$(( COMPL_EXT + 1 ))
        COMPL_DIR=$( epath_join ${CONFIG[TARGET_DIR]} "${COMPL_SUB}.${COMPL_EXT}" )
    done
    # Too many backups!
    if [[ $COMPL_EXT -gt 999 ]]; then
        echo "ERROR: Too many backups for single date (Max of 999): ${TODAY}"
        exit 1
    fi
    log_entry "| Renaming: ${CONFIG[RUNNING_DIRNAME]} => $( basename $COMPL_DIR )"
    # Rename to complete dir
    mv $RUN_DIR $COMPL_DIR
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not rename completed backup to: ${COMPL_DIR}"
        exit 1
    fi
    touch $COMPL_DIR
}

###############################
## Shortcut function to create an escaped fullpath for a given num dir
##  $1 -> Num of subdir
##  $2 -> Number of left-padded zeroes
## Outputs the escaped full path
rotate_subdir_num() {
    NUM=$( printf "%0$(( $2 + 1 ))d" $1 )
    NUMDIR=$( echo ${CONFIG[ROTATE_SUBDIR]} | sed "s/NUM0*[01]/$NUM/" )
    FULL_SUBDIR=$( epath_join ${CONFIG[TARGET_DIR]} ${NUMDIR} )
    echo $FULL_SUBDIR
}

###############################
## Having completed a running backup, rotate number based subdirectories
##  $1 -> Starting number to represent most recent backup; must be 0 or 1
##  $2 -> Number of left-padded zeroes; default of 0
rotate_complete_num() {
    FIRST_N=$1
    PAD=${2:-0}
    LAST_N=$(( $FIRST_N + ${CONFIG[MAX_ROTATIONS]} - 1 ))
    # Attempt to locate a gap
    GAP_N=""
    for N in $( seq $FIRST_N $LAST_N ); do
        GAP_DIR=$( rotate_subdir_num $N $PAD)
        if [[ ! -d $GAP_DIR ]]; then
            GAP_N=$N
            break
        fi
    done
    if [[ $GAP_N != "" ]]; then
        LAST_N=$GAP_N
    fi
    # If last directory already exists, we cannot rotate
    LAST_DIR=$( rotate_subdir_num $LAST_N $PAD )
    if [[ -d $LAST_DIR ]]; then
        echo "ERROR: Could not rotate due to directory already existing: ${LAST_DIR}"
        exit 1
    fi
    # Rotate directories
    for N in $( seq $(( LAST_N - 1 )) -1 $FIRST_N ); do
        ROT_FROM=$( rotate_subdir_num $N $PAD )
        ROT_TO=$( rotate_subdir_num $(( N + 1 )) $PAD )
        log_entry "| Renaming: $( basename $ROT_FROM ) => $( basename $ROT_TO )"
        mv $ROT_FROM $ROT_TO
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to rotate directory from ${ROT_FROM} to ${ROT_TO}"
            exit 1
        fi
    done
    # Rename running dir
    FIRST_DIR=$( rotate_subdir_num $FIRST_N $PAD )
    log_entry "| Renaming: ${CONFIG[RUNNING_DIRNAME]} => $( basename $FIRST_DIR )"
    mv $RUN_DIR $FIRST_DIR
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not rename directory from ${RUN_DIR} to ${FIRST_DIR}"
        exit 1
    fi
    touch $FIRST_DIR
}

