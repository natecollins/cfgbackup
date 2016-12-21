###############################
# Misc helper functions
###############################

###############################
## Creates an array of config variables with default values
##  $1 -> Array to search
##  $2 -> Value to find
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
## Get the index of a matching substring within a string
##  $1 -> String to search
##  $2 -> Substring to match
## Returns index of matching substring; returns -1 if not found
substr_index() {
    local HAYSTACK="$1"
    local NEEDLE="$2"
    local PREMATCH="${HAYSTACK%%$NEEDLE*}"
    if [[ $PREMATCH != $HAYSTACK ]]; then
        return ${#PREMATCH}
    fi
    return -1
}


