###############################
# Rotation Functions
###############################

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

