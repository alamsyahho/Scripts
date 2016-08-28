#!/bin/bash

# Change the following to suit you environment
# WARNING DO NOT PUT SPACES IN BETWEEN THE VARIABLES BELOW

LOCAL_DIR=/home/foo
REMOTE_DIR=/home/remoteuser/remote_dir
TMP_LOG="/tmp/backup.log"
SERVER_LIST=/home/foo/server_list
EMAIL_TO="foo@example.com"

##### DO NOT CHANGE THE FOLLOWING SETTINGS ######
DATE=`which date`
HOSTNAME=`hostname`
MKDIR=`which mkdir`
RM=`which rm`
WC=`which wc`
CAT=`which cat`
SSH=`which ssh`
SCP=`which scp`
LS=`which ls`

echo "Start Time: `$DATE`"

echo

echo
echo "Starting to backup log ..." >> $TMP_LOG
echo

declare -a SERVER=`$CAT $SERVER_LIST`
NO_OF_SERVER=`$CAT $SERVER_LIST|$WC -l`

for (( a=0 ; a < "$NO_OF_SERVER" ; a++ ))
do

	declare -a DIRECTORY=`$CAT $REMOTE_DIR`
	NO_OF_DIRECTORY=`$CAT $REMOTE_DIR|$WC -l`

	for (( b = 0 ; b < "$NO_OF_DIR" ; b++ ))
	do
	       	declare -a FILE=(`$SSH ${SERVER[$a]} '$LS ${DIRECTORY[$b]}'`)
	       	declare NO_OF_FILE=(`$SSH ${SERVER[$a]} '$LS ${DIRECTORY[$b]}'`|$WC -l`)

		for (( c=0 ; c < "$NO_OF_FILE" ; c++ ))
		do
			declare CHECK_FILE=($LS $LOCAL_DIR/${DIRECTORY[$b]} |$GREP ${FILE[$c]} |$WC -l)
			if [ "$CHECK_FILE"= "1" ] then
				echo "${FILE[$c]} already exist. Skip copying..." >> $TMP_LOG
			else
				if [ ! -d "$LOCAL_DIR/${DIRECTORY[$b]}" ]; then
					$MKDIR -p ${DIRECTORY[$b]}
				fi

				echo "Copying ${FILE[$c]} to $LOCAL_DIR/${DIRECTORY[$b]}" >> $TMP_LOG
				$SCP ${SERVER[$a]}:~/${DIRECTORY[$b]}/${FILE[$c]} $LOCAL_DIR/${DIRECTORY[$b]}
			fi

		done
	done
done


echo >> $TMP_LOG
echo "Completed ..." >> $TMP_LOG
echo "End Time  : `$DATE`" >> $TMP_LOG


#
# To send mail out
#
$CAT $TMP_LOG | $MAIL -s "$HOSTNAME - Server log backup status" $EMAIL_TO

#
# To remove TMP_LOG after use
#
$RM -f $TMP_LOG
