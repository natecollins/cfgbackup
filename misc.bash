#######################################
# HELPER FUNCTIONS
#######################################

###############################
## Check if array contains a given value
##  $1 -> Name of array to search
##  $2 -> Value to find
## Returns 0 if an element matches the value to find
array_contains() {
    local ARRNAME=$1[@]
    local HAYSTACK=( ${!ARRNAME} )
    local NEEDLE="$2"
    for VAL in "${HAYSTACK[@]}"; do
        if [[ $NEEDLE == $VAL ]]; then
            return 0
        fi
    done
    return 1
}

###############################
## Get the index of matched value from an indexed array
##  $1 -> Name of array to search
##  $2 -> Value to find
## Prints the index of matching value; prints -1 if value not found
array_value_index() {
    local ARRNAME=$1[@]
    local HAYSTACK=( ${!ARRNAME} )
    local NEEDLE="$2"
    for KEY in "${!HAYSTACK[@]}"; do
        if [[ $NEEDLE == ${HAYSTACK[$KEY]} ]]; then
            echo $KEY
            return
        fi
    done
    echo -1
}

###############################
## Get the index of a matching substring within a string
##  $1 -> String to search
##  $2 -> Substring to match
## Prints the index of matching substring; prints -1 if not found
substr_index() {
    local HAYSTACK="$1"
    local NEEDLE="$2"
    local PREMATCH="${HAYSTACK%%$NEEDLE*}"
    if [[ $PREMATCH != $HAYSTACK ]]; then
        echo ${#PREMATCH}
    fi
    echo -1
}

###############################
## Combine two strings into a full file/directory path
##  $1 -> First part of path, may not be empty
##  $2 -> Second part of path
## Returns the combined path, with no trailing slash
path_join() {
    if [[ $1 == "" ]]; then
        echo "ERROR: Cannot path_join empty string."
        exit 1
    fi
    PATH1="${1%/}"
    PATH2="${2%/}"
    PATH2="${PATH2#/}"
    if [[ $PATH2 != "" ]]; then
        PATH2="/${PATH2}"
    fi
    echo "${PATH1}${PATH2}"
}

###############################
## Combine two strings into a full file/directory path, and
## escapes the resulting string for use in a command
##  $1 -> First part of path, may not be empty
##  $2 -> Second part of path
## Returns the combined path, with no trailing slash, escaped
epath_join() {
    P=$( path_join "$1" "$2" )
    printf '%q' "$P"
}

###############################
## Check if rsync is found
## Returns 0 if found and executable
rsync_exists() {
    DUMMY=$( ${CONFIG[RSYNC_PATH]} --version 2>&1 )
    return $?
}

###############################
## Check if hardlink is found
## Returns 0 if found and executable
hardlink_exists() {
    DUMMY=$( ${CONFIG[HARDLINK_PATH]} -h 2>&1 )
    return $?
}

###############################
## Get what version of rsync are we using
## Outputs the rsync verion number, e.g. 3.1.0
version_rsync() {
    ${CONFIG[RSYNC_PATH]} --version | head -n 1 | awk '{ print $3 }'
}

###############################
## Is the rsync version at least 3.1.0
## Returns 0 if version 3.1.0 or greater
rsync_gte_310() {
    RSYNC_VER=$( version_rsync )
    RSYNC_CHECK=$( echo -e "${RSYNC_VER}\n3.1.0" | ${CONFIG[SORT_PATH]} -V | head -n 1 )
    if [[ $RSYNC_CHECK == "3.1.0" ]]; then
        return 0;
    fi
    return 1
}

###############################
## Is the running version of bash at least 4.3.0
## Returns 0 if version 4.3.0 or greater
bash_gte_430() {
    BASH_VCHECK=$( echo -e "${BASH_VERSION}\n4.3.0" | ${CONFIG[SORT_PATH]} -V | head -n 1 )
    if [[ $BASH_VCHECK == "4.3.0" ]]; then
        return 0;
    fi
    return 1
}

###############################
## Check for sort from coreutils with version sort
## Return 0 if sort -V works
coreutils_sort() {
    DUMMY=$( echo | ${CONFIG[SORT_PATH]} -V )
    if [[ $? -eq 0 ]]; then
        return 0
    fi
    return 1
}

