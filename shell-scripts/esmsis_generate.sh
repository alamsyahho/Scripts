#!/bin/bash

# This script will truncate pooling.jawaban
# and also set date for pooling from 15 of current month to the end of month

GENERATE_RESULT='/home/esmsis/script/generate_csv.sql'
RESULT_CSV='/tmp/result.csv'
MAIL_SENDER='SystemNotification@example.com'
MAIL_SUBJECT="Esmsis Pooling Report `date "+%B %Y" -d "now - 1 month"`"
MAIL_SMTP='1.1.1.1:25'
MAIL_TO='foo@example.com'

################## DO NOT CHANGE ANYTHING BELOW ############################

RM=`which rm`
SED=`which sed`
DATE=`which date`
MYSQL=`which mysql`
MAILX=`which mailx`
PRINTF=`which printf`
LAST_MONTH=`$DATE "+%B %Y" -d "now - 1 month"`

# Cleanup result
$RM -f $RESULT_CSV

# Generate report in csv file
$MYSQL < $GENERATE_RESULT

# Replace string
$SED -i "s/+/'/g" $RESULT_CSV

# Sent notification email to user
$PRINTF "%b" "Dear esmsis user,\n\nPlease find the attached csv file as the pooling result for $LAST_MONTH\n\n\nCheers,\n\nEsmsis Administrator" | /bin/mailx -a $RESULT_CSV -r "$MAIL_SENDER" -s "$MAIL_SUBJECT" -S smtp="$MAIL_SMTP" $MAIL_TO
