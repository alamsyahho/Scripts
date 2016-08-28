#!/bin/bash
# redis-notify.sh

MAILGUN_DOMAIN="account.example.com"
MAILGUN_KEY="key-somerandonmailgunkey"
MAILFROM="alerts <alerts@example.com>"
MAILTO="admin@example.com"
MAILSUBJECT="Redis Notification"
MAILBODY=`cat << EOB
============================================
Redis Notification Script called by Sentinel
============================================
Event Type: ${1}
Event Description: ${2}

Check the redis status.
EOB`

if [[ "$#" = "2" ]]; then
    curl -s --user "api:${MAILGUN_KEY}" \
        https://api.mailgun.net/v3/${MAILGUN_DOMAIN}/messages \
        -F from="${MAILFROM}" \
        -F to="${MAILTO}" \
        -F subject="${MAILSUBJECT}" \
        -F text="${MAILBODY}"
fi
