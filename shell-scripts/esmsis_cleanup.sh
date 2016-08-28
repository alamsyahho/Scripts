#!/bin/bash

# This script will truncate pooling.jawaban
# and also set date for pooling from 15 of current month to the end of month

DB_NAME='pooling'
POOLING_TABLE='pooling'
JAWABAN_TABLE='jawaban'
MAIL_SENDER='SystemNotification@example.com'
MAIL_SUBJECT='Esmsis Cleanup Notification'
MAIL_SMTP='1.1.1.1:25'
MAIL_TO='foo@example.com'

################## DO NOT CHANGE ANYTHING BELOW ############################

DATE=`which date`
MYSQL=`which mysql`
MAILX=`which mailx`
PRINTF=`which printf`
CUR_YEAR=`$DATE +%Y`
CUR_MONTH=`$DATE +%m`
MID_DAY='15'
LAST_DAY=`$DATE +%d -d "$CUR_MONTH/1 + 1 month - 1 day"`
NOW=`$DATE "+%Y-%m-%d %H-%M-%S"`

# Truncate jawaban
$MYSQL -e "truncate $DB_NAME.$JAWABAN_TABLE"

# Update pooling table date startDate="mid day of month" and endDate="last day of month"
$MYSQL -e "UPDATE $DB_NAME.$POOLING_TABLE SET startDate = '$CUR_YEAR-$CUR_MONTH-$MID_DAY', endDate = '$CUR_YEAR-$CUR_MONTH-$LAST_DAY', lastEdit = '$NOW' WHERE (id = 3)"
$MYSQL -e "UPDATE $DB_NAME.$POOLING_TABLE SET startDate = '$CUR_YEAR-$CUR_MONTH-$MID_DAY', endDate = '$CUR_YEAR-$CUR_MONTH-$LAST_DAY', lastEdit = '$NOW' WHERE (id = 4)"

# Sent notification email to user
$PRINTF "%b" "Dear esmsis user,\n\nAutomatic maintenance has been done on esmsis as below:\n1. Table $DB_NAME.$JAWABAN_TABLE from esmsis has been cleaned.\n2. Pooling date has been set from $CUR_YEAR-$CUR_MONTH-$MID_DAY to $CUR_YEAR-$CUR_MONTH-$LAST_DAY\n\nYou can now resume the monthly pooling and send the broadcast message to customers\n\n\nCheers,\n\nEsmsis Administrator" | /bin/mailx -r "$MAIL_SENDER" -s "$MAIL_SUBJECT" -S smtp="$MAIL_SMTP" $MAIL_TO
