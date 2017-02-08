###############################
# Email Functions
###############################

###############################
## Check if mail command exists
mail_exists() {
    command -v mail > /dev/null
    return $?
}

###############################
## Attempt to send an email
##  $1 -> Recipient address
##  $2 -> Subject
##  $3 -> Message
mailer() {
    RECIPIENT=$1
    SUBJECT=$2
    MESSAGE=$3
    echo -e $MESSAGE | ${CONFIG[MAIL_PATH]} -s "$SUBJECT" $RECIPIENT

    if [[ $? != 0 ]]; then
        # Log mail failure
        log_entry "| FAILED to send email to ${RECIPIENT}. Subject: \"$SUBJECT\""
        echo "FAILED to send email to ${RECIPIENT}. Subject: \"$SUBJECT\""
        return 1
    fi
    return 0
}

###############################
## Attempt to send an failure notifcation about rsync exit code
##  $1 -> The rsync exit code
mailer_rsync_exit() {
    if [[ ${CONFIG[NOTIFY_EMAIL]} != "" ]]; then
        mailer "${CONFIG[NOTIFY_EMAIL]}" "cfgbackup job '${CONF_NAME}' failed with exit code $RSYNC_EXIT" "
The rsync command used in the '${CONF_NAME}' backup job exited with code ${RSYNC_EXIT}.

For more details, view the log file: $LOG_FILE
"
    fi
}

