#!/bin/bash

# Script to check if there are any cron or scheduler that is not executed in given day

MAILGUN_DOMAIN="account.example.com"
MAILGUN_KEY="key-somerandonmailgunkey"
MAILFROM="alerts <alerts@example.com>"
MAILTO="admin@example.com"
MAILSUBJECT="YourDomain Daily Scheduler Report `date '+%d %B %Y'` on `hostname -s`"
MAILTMP='/tmp/scheduler-appname.tmp'
LOGS="/path/to/your/schedulerlog"
LIST="
billing:subscription
billing:checkCardExpiry
user:unsubscribe
user:email_non-autocharge_expiring
billing:generate-subscritions-report
billing:reconcilePayments
reports:daily.summary"

#
# Set EMAIL=0 so it won't send email by default
#
EMAIL="0"

#
# Check scheduler_out log
#
for x in ${LIST}; do
    if ( grep $x ${LOGS} > /dev/null ); then
        echo "Checking scheduled jobs $x logs ...... [ FOUND ]" >> ${MAILTMP}
    else
        EMAIL="1"
        echo "Checking scheduled jobs $x logs ...... [ NOT FOUND ]" >> ${MAILTMP}
    fi
done

if [[ "$EMAIL" == 1 ]]; then
    sed -i '1i--------------------------------' ${MAILTMP}
    sed -i '1iSome scheduled jobs are not running. Please check the details below' ${MAILTMP}
    MAILBODY=`cat ${MAILTMP}`
    curl -s --user "api:${MAILGUN_KEY}" \
        https://api.mailgun.net/v3/${MAILGUN_DOMAIN}/messages \
        -F from="${MAILFROM}" \
        -F to="${MAILTO}" \
        -F subject="${MAILSUBJECT}" \
        -F text="${MAILBODY}"
fi

#
# Remove MAILTMP
#
rm -rf ${MAILTMP}
