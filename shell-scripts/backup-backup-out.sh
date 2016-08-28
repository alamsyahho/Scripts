#!/bin/bash

# Last Update: 5 July 2011
# Author: Alamsyah
# Script to automate backup apache and mail log to specified mail

BASEDIR=/home/clu
BASEDIR_OWNER=clu
EMAIL_TO="serveralert@example.com"
TMP_LOG="/tmp/backup-out.log"
BACKUP_DIR=/var2/backup/backup-out

##### DO NOT CHANGE THE FOLLOWING SETTINGS #####
DATE=`which date`
MKDIR=`which mkdir`
RM=`which rm`
MV=`which mv`
TAR=`which tar`
DU=`which du`
AWK=`which awk`
CAT=`which cat`
MAIL=`which mail`
FIND=`which find`
CHOWN=`which chown`

################################################

echo "Start Time: `$DATE`" > $TMP_LOG
echo >> $TMP_LOG
echo "Backup backup-out on $HOSTNAME" >> $TMP_LOG
echo >> $TMP_LOG

DIRECTORY=`$FIND $BASEDIR -name "backup-out" -type d`
ZIP_DIR=`cd $DIRECTORY/..; pwd`
ZIP_FILE=backup-out.`date +%Y%m%d`.tar.bz2

echo "Found backup-out directory on $DIRECTORY" >> $TMP_LOG
echo >> $TMP_LOG

SIZE=`$DU -hs $DIRECTORY|$AWK '{print $1}'`
echo "Compressing backup-out directory with total size $SIZE" >> $TMP_LOG
cd $ZIP_DIR
$TAR -cjf $ZIP_FILE backup-out/

SIZE=`$DU -hs $ZIP_DIR/$ZIP_FILE |$AWK '{print $1}'`
echo "Done Compressing $ZIP_FILE to $SIZE" >> $TMP_LOG

if [ ! -d "$DIRECTORY" ]; then
	$MKDIR -p $BACKUP_DIR
fi

$MV $ZIP_DIR/$ZIP_FILE $BACKUP_DIR

echo >> $TMP_LOG
echo "Completed ..." >> $TMP_LOG
echo "End Time  : `$DATE`" >> $TMP_LOG

$RM -rf $DIRECTORY
$MKDIR $DIRECTORY
$CHOWN -R $BASEDIR_OWNER. $DIRECTORY

#
# To send mail out
#
$CAT $TMP_LOG | $MAIL -s "$HOSTNAME - backup-out Backup Status" $EMAIL_TO

#
# To remove TMP_LOG after use
#
$RM -f $TMP_LOG
