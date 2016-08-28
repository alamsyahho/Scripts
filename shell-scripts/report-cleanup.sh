#!/bin/bash

## SCRIPT TO DELETE OLDER FILES THAN 6 MONTHS ##
## CREATED BY ALAMSYAH ##
## LAST UPDATE ON 4 JULY 2011 ##

BASEDIR=/path/to/yourworkdir
CLEANUP_DIR=report
EMAIL_TO=serveralert@example.com
TMP_LOG=/tmp/reportcleanup.log

##### DO NOT CHANGE THE FOLLOWING SETTINGS #####
DATE=`which date`
LS=`which ls`
GREP=`which grep`
FIND=`which find`
RM=`which rm`
WC=`which wc`
MAIL=`which mail`
CAT=`which cat`

###############################################
echo "Start Time: `$DATE`" > $TMP_LOG

echo >> $TMP_LOG
echo "Gateway Report Directory Cleanup on $HOSTNAME" >> $TMP_LOG
echo >> $TMP_LOG

declare -a DIRECTORY=(`$FIND $BASEDIR -name $CLEANUP_DIR -type d`)
NO_OF_DIRECTORY=(`$FIND $BASEDIR -name $CLEANUP_DIR -type d|$WC -l`)

for (( x = 0 ; x < "$NO_OF_DIRECTORY" ; x++ ))
do
	for (( y = 7 ; y <= 60 ; y++ ))
	do
		LOOP_DATE=`$DATE +%Y%m -d "-$y month"`
		ECHO_DATE=`$DATE "+%B %Y" -d "-$y month"`
		declare -a FILES=(`$LS ${DIRECTORY[$x]} | $GREP $LOOP_DATE`)
		NO_OF_FILES=(`$LS ${DIRECTORY[$x]} | $GREP $LOOP_DATE | $WC -l`)

		if [ $NO_OF_FILES != 0 ]; then
			echo >> $TMP_LOG
			echo "Delete this following files in ${DIRECTORY[$x]} that related to $ECHO_DATE" >> $TMP_LOG
		fi

		for (( z = 0 ; z < "$NO_OF_FILES" ; z++ ))
		do
			echo "---- ${FILES[$z]}" >> $TMP_LOG
			$RM -rf ${DIRECTORY[$x]}/${FILES[$z]}
		done
	done
done

echo >> $TMP_LOG
echo "Completed ..." >> $TMP_LOG
echo "End Time  : `$DATE`" >> $TMP_LOG

#
# To send mail out
#
$CAT $TMP_LOG | $MAIL -s "$HOSTNAME - Gateway Report Directory Maintenance Status" $EMAIL_TO

#
# To remove TMP_LOG after use
#
$RM -f $TMP_LOG
