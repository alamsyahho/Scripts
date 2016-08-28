#!/bin/bash

# Last Update: 5 July 2011
# Author: Alamsyah
# Script to automate backup apache and mail log to specified mail

BASEDIR=/home/clu/apachelog
EMAIL_TO="serveralert@example.com"
TMP_LOG="/tmp/backupapache.log"

##### DO NOT CHANGE THE FOLLOWING SETTINGS #####
DATE=`which date`
LS=`which ls`
GREP=`which grep`
MKDIR=`which mkdir`
RM=`which rm`
CP=`which cp`
WC=`which wc`
MV=`which mv`
TAR=`which tar`
DU=`which du`
AWK=`which awk`
CAT=`which cat`
MAIL=`which mail`

##Remove previous directory
$RM -rf $BASEDIR

## create target backup dir
$MKDIR -p $BASEDIR/apache.log.`date +%Y%m%d`

## set all selected log file to blank

echo "Start Time: `$DATE`" > $TMP_LOG

echo >> $TMP_LOG
echo "Backup Apache log on $HOSTNAME" >> $TMP_LOG
echo >> $TMP_LOG

declare -a APACHE=(`$LS /var/log/ |$GREP apache2`)
NO_OF_APACHE=(`$LS /var/log/ |$GREP apache2|$WC -l`)

for (( x = 0 ; x < "$NO_OF_APACHE" ; x++ ))
do
	declare -a LOG=(`$LS /var/log/${APACHE[$x]}`)
	NO_OF_LOG=(`$LS /var/log/${APACHE[$x]}|$WC -l`)
	for (( y = 0 ; y < "$NO_OF_LOG" ; y++ ))
	do
		$MKDIR -p $BASEDIR/apache.log.`date +%Y%m%d`/${APACHE[$x]}
		SIZE=`$DU -hs /var/log/${APACHE[$x]}/${LOG[$y]}|$AWK '{print $1}'`
		echo "Backup ${APACHE[$x]}/${LOG[$y]} size $SIZE" >> $TMP_LOG
		$CP /var/log/${APACHE[$x]}/${LOG[$y]} $BASEDIR/apache.log.`date +%Y%m%d`/${APACHE[$x]}
		cat /dev/null > /var/log/${APACHE[$x]}/${LOG[$y]}
	done
	echo >> $TMP_LOG
done

##
## gzip tarball the backup file
SIZE=`$DU -hs $BASEDIR|$AWK '{print $1}'`
echo "Compressing apache log file with total size $SIZE" >> $TMP_LOG
cd $BASEDIR
$TAR -cjf apache.log.`date +%Y%m%d`.tar.bz2 apache.log.`date +%Y%m%d`

SIZE=`$DU -hs $BASEDIR/apache.log.*.tar.bz2 |$AWK '{print $1}'`
echo "Done Compressing apache.log.`date +%Y%m%d`.tar.bz2  to $SIZE" >> $TMP_LOG

$MV $BASEDIR/apache.log.`date +%Y%m%d`.tar.bz2 /var2/backup/apachelog

## remove target dir/file after compressed
$RM -rf $BASEDIR

echo >> $TMP_LOG
echo "Completed ..." >> $TMP_LOG
echo "End Time  : `$DATE`" >> $TMP_LOG

#
# To send mail out
#
$CAT $TMP_LOG | $MAIL -s "$HOSTNAME - Apache backup status" $EMAIL_TO

#
# To remove TMP_LOG after use
#
$RM -f $TMP_LOG
