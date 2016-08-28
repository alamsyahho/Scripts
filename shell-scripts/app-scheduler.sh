#!/bin/bash

# Script to run laravel scheduler job through anacron
# If any error are generated when running anacron, email notification will be send to sysadmin email 

# GLOBAL CONFIG FOR EMAIL
MAILGUN_DOMAIN="account.example.com"
MAILGUN_KEY="key-somerandonmailgunkey"
MAILFROM="alerts <alerts@example.com>"
MAILTO="admin@example.com"

# APP SPECIFIC CONFIG
MAILSUBJECT="AppName Scheduler Alert for:"
OUTLOG="/var/www/sites/api.example.com/storage/logs/scheduler_out.log"
COMMAND="/usr/bin/php /var/www/sites/api.example.com/artisan"
CRONLIST="
user:exec1
gateway:exec1
billing:exec1
reports:exec1"

#
# Start Script
#

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for x in ${CRONLIST}; do
    # restore $IFS
    IFS=$SAVEIFS

    date >> ${OUTLOG}
    echo "Running scheduled command: /usr/bin/php $x" >> ${OUTLOG}
    OUTPUT="Error log for $x:"$'\n'$'\n'"$( ${COMMAND} $x )"
    if [[ "$?" == 1 ]]; then
        curl -s --user "api:${MAILGUN_KEY}" \
            https://api.mailgun.net/v3/${MAILGUN_DOMAIN}/messages \
            -F from="${MAILFROM}" \
            -F to="${MAILTO}" \
            -F subject="${MAILSUBJECT} $x" \
            -F text="${OUTPUT}"
    fi
done
 
