#!/bin/bash

# Ensure run dir is script dir
SCRIPT_DIR=$( dirname $(readlink -f "${BASH_SOURCE[0]}") )
pushd "$SCRIPT_DIR" > /dev/null

runhelp() {
    echo ""
    echo "Usage: run-checks [FLAGS]"
    echo ""
    echo "FLAGS:"
    echo "  -a|--all            Run all tests and checks."
    echo "  -s|--shellcheck     Run shellcheck."
    echo "  -u|--unittests      Run the unittests."
    echo ""
}

if [[ -z "$1" || $1 == "-h" || $1 == "--help" || $1 == "help" || $1 == "-V" || $1 == "--version" ]]; then
    runhelp
    exit 0
fi

parse_args() {
    declare -g -A ARGS
    ARGS[UNITTESTS]=0
    ARGS[SHELLCHECK]=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -a|--all)
            ARGS[UNITTESTS]=1
            ARGS[SHELLCHECK]=1
            shift
            ;;
        -s|--shellcheck)
            ARGS[SHELLCHECK]=1
            shift
            ;;
        -u|--unittests)
            ARGS[UNITTESTS]=1
            shift
            ;;
        *)
            echo "Unknown argument: ${1}"
            exit 1
            ;;
        esac
    done
}

msg() {
    [[ -n "$TEST_FILE" ]] && PREFIX="(${TEST_FILE}) "
    1>&2 echo "${PREFIX}$1"
}

run_shellcheck() {
    # -s shellcheck
    if [[ "${ARGS[SHELLCHECK]}" -eq 1 ]]; then
        msg "Proceeding with shellcheck."
        if ! shellcheck cfgbackup; then
            echo "FAILURE: shellcheck did not succeed"
            exit 1
        fi
    fi
}

run_unittests() {
    # -u unit tests
    if [[ "${ARGS[UNITTESTS]}" -eq 1 ]]; then
        msg "Proceeding with unit tests."
        for TEST_FILE in tests/test*.sh; do
            msg "Loading tests."
            source "$TEST_FILE"
            if [[ "$( type -t test_pre )" == "function" ]]; then
                test_pre
                unset -f test_pre
            fi
            if [[ "$( type -t test_run )" != "function" ]]; then
                echo "FAILURE: File $TEST_FILE is missing function: test_run"
                exit 1
            fi
            test_run
            EXIT=$?
            if [[ "$EXIT" -ne 0 ]]; then
                echo "FAILURE: Test in $TEST_FILE returned $EXIT"
                exit 1
            fi
            unset -f test_run
            if [[ "$( type -t test_post )" == "function" ]]; then
                test_post
                unset -f test_post
            fi
        done
        TEST_FILE=""
    fi
}

parse_args "$@"
source cfgbackup
run_shellcheck
run_unittests
msg "Testing complete!"
