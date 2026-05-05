#!/bin/bash

# unit testing for function: split_args

test_pre() {
    :
}

test_run() {
    # Test 1
    PARSED=$( split_args "-v" "-vab" "--more" "--" "-pq" "--less" "file.txt" )
    [[ ${PARSED} == "-v -v -a -b --more -pq --less file.txt" ]] ||
        (msg "incorrect args returned: $PARSED" && return 1)
}

test_post() {
    :
}
