###############################
# Misc helper functions
###############################

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
## Trim pattern from both beginning and end of string
##  $1 -> The string to trim from
##  $2 -> The pattern to trim
## Prints out the trimmed string
str_trim() {
    local FULLSTR="$1"
    local PTRN="$2"
    local TRIMSTR="${FULLSTR%%$PTRN}"
    TRIMSTR="${TRIMSTR##$PTRN}"
    echo $TRIMSTR
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
    echo "$PATH1/$PATH2"
}



