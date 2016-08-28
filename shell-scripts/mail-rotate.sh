#!/bin/sh

# Spool mail cleanup script
# Written by Alamsyah

MAILDIR=/var/spool/mail
TMP_LOG=/tmp/mail-rotate.log
EMAIL_TO=serveralert@example.com

##### DO NOT CHANGE THE FOLLOWING SETTINGS #####
DATE=`which date`
LS=`which ls`
RM=`which rm`
MAIL=`which mail`
CAT=`which cat`
LS=`which ls`
###############################################


echo "Start Time: `$DATE`" > $TMP_LOG

echo >> $TMP_LOG
echo "Spool Mail Directory Cleanup on $HOSTNAME" >> $TMP_LOG
echo >> $TMP_LOG

for i in `ls -1 $MAILDIR`;
do
$CAT /dev/null > $MAILDIR/$i
done

$LS -lh $MAILDIR/* >> $TMP_LOG

echo >> $TMP_LOG
echo "Completed ..." >> $TMP_LOG
echo "End Time  : `$DATE`" >> $TMP_LOG

#
# To send mail out
#
$CAT $TMP_LOG | $MAIL -s "$HOSTNAME - Spool Mail Cleanup Status" $EMAIL_TO

#
# To remove TMP_LOG after use
#
$RM -f $TMP_LOG


# EOF
