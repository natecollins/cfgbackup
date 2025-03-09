#!/bin/bash

# unit testing for function: array_value_index

test_pre() {
    :
}

test_run() {
    # Test 1
    declare -g -A ARR1=([a]=one [b]=two [c]=three)
    KEY2=$( assoc_array_value_index ARR1 "two" )
    [[ ${KEY2} == "b" ]] ||
        (msg "array value incorrect: $KEY2" && return 1)

    declare -g -A ARR2=([alpha]=one [beta]=two [gamma]=three)
    KEY2=$( assoc_array_value_index ARR2 "two" )
    [[ ${KEY2} == "beta" ]] ||
        (msg "array value incorrect: $KEY2" && return 1)
}

test_post() {
    :
}
