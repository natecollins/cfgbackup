###############################
# Misc helper functions
###############################

###############################
## Creates an array of config variables with default values
array_contains() {
    local HAYSTACK="$1[@]"
    local NEEDLE="$2"
    for VAL in "${!HAYSTACK}"; do
        if [[ $NEEDLE == $VAL ]]; then
            return 0
        fi
    done
    return 1
}

