#!/bin/bash
# Author: Alamsyah
# Revision Date: 20141021
# Backup and auto deploy script for jboss

APP_NAME=""
BACKUP_TARGET=""
SOURCE_DIR=""
DEPLOY_DIR=""
BACKUP_DIR="/var/backup"
JBOSS_INIT=""
MAIL_TO=""

#------------ DO NOT CHANGE THE FOLLOWING SETTINGS -------------------

MKDIR=`which mkdir`
MD5SUM=`which md5sum`
AWK=`which awk`
PS=`which ps`
GREP=`which grep`
RSYNC=`which rsync`
DATE=`which date`
KILL=`which kill`
CAT=`which cat`
MAIL=`which mail`

#---------------------------------------------------------------------

# Check if backup_target exist, if not end script
if [ ! -f "$SOURCE_DIR/$BACKUP_TARGET" ]; then
        exit 1
fi

# Create backup folder if not exist
if [ ! -d "$BACKUP_DIR/$APP_NAME" ]; then
        $MKDIR -p $BACKUP_DIR/$APP_NAME
fi

# Compare md5um, if same then skip backup, if differ then proceed with backup and restart jboss
MD5SUM_SOURCE=`$MD5SUM $SOURCE_DIR/$BACKUP_TARGET | $AWK '{print $1}'`
MD5SUM_DEPLOY=`$MD5SUM $DEPLOY_DIR/$BACKUP_TARGET | $AWK '{print $1}'`
PID_JBOSS=`$PS ax | $GREP java | $GREP jboss | $AWK '{print $1}'`
LOG_BACKUP="/tmp/backup_$APP_NAME.log"

if [ "$MD5SUM_SOURCE" != "$MD5SUM_DEPLOY" ]; then
        echo "Start Time: `$DATE`" > $LOG_BACKUP

        echo >> $LOG_BACKUP
        echo "Start backup on $HOSTNAME for $BACKUP_TARGET ..." >> $LOG_BACKUP
        echo "-------------------------------------------------">> $LOG_BACKUP
        echo >> $LOG_BACKUP

        # Backup file from deploy dir to backup dir
        echo "Backup $BACKUP_TARGET to $BACKUP_DIR/$APP_NAME/$BACKUP_TARGET.bak`$DATE +'%Y%m%d'`" >> $LOG_BACKUP
        echo >> $LOG_BACKUP
        $RSYNC -av $DEPLOY_DIR/$BACKUP_TARGET $BACKUP_DIR/$APP_NAME/$BACKUP_TARGET.bak`$DATE +'%Y%m%d'`

        # Copy file from source dir to deploy dir for auto deploy
        echo "Deploy new $BACKUP_TARGET with md5 value of $MD5SUM_SOURCE" >> $LOG_BACKUP
        echo >> $LOG_BACKUP
        $RSYNC -av $SOURCE_DIR/$BACKUP_TARGET $DEPLOY_DIR/$BACKUP_TARGET

        # Stop jboss by init
        $JBOSS_INIT stop

        # Wait for 2 minutes before force killing the process
        COUNT=1
        while $PS -p $PID_JBOSS > /dev/null
        do
                if [ $COUNT -gt 20 ]; then
                        $KILL -9 $PID_JBOSS
                        echo "Force kill $APP_NAME with pid $PID_JBOSS" >> $LOG_BACKUP
                        echo >> $LOG_BACKUP
                fi
                sleep 6
                COUNT=$((COUNT+1))
        done
		
        # Start jboss after deploy
        $JBOSS_INIT start
        sleep 5

        PID_JBOSS=`$PS ax | $GREP java | $GREP jboss | $AWK '{print $1}'`
        echo "$APP_NAME on $HOSTNAME" successfully started with pid $PID_JBOSS >> $LOG_BACKUP
        $PS axu | $GREP java | $GREP jboss >> $LOG_BACKUP

        echo >> $LOG_BACKUP
        echo "-------------------------------------------------">> $LOG_BACKUP
        echo "Completed ..."  >> $LOG_BACKUP
        echo "End Time  : `$DATE`"  >> $LOG_BACKUP
		
		# To send mail out
		$CAT $LOG_BACKUP | $MAIL -s "$HOSTNAME - $APP_NAME backup status" $MAIL_TO
fi

exit 0