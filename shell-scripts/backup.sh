#!/bin/bash

# Days to keep log
DAYS=30

CAT=`which cat`
AWK=`which awk`
WC=`which wc`
TAR=`which tar`
DATE=`which date`
HOSTNAME=`hostname -s`
MKDIR=`which mkdir`
RM=`which rm`

BACKUP_DIR="/root/bin/list_backup"
COUNT=`$CAT /root/bin/list_backup|$WC -l`

STORE_DIR="/nfs/backup/$HOSTNAME/`$DATE +'%Y%m%d'`"

if [ ! -d "$STORE_DIR" ]; then
        $MKDIR -p $STORE_DIR
fi

for (( x=2; x<=$COUNT; x++ ))
do
        BACKUP_NAME=`$CAT $BACKUP_DIR | $AWK -v x=$x 'NR==x {print $1}'`
        BACKUP_DIRECTORY=`$CAT $BACKUP_DIR | $AWK -v x=$x 'NR==x {print $2}'`
        BACKUP_TARGET=`$CAT $BACKUP_DIR | $AWK -v x=$x 'NR==x {print $3}'`
        $TAR cjf $STORE_DIR/$BACKUP_NAME.tar.bz2 --directory=$BACKUP_DIRECTORY $BACKUP_TARGET
done

# Remove backup more than 30 days
find /nfs/backup/$HOSTNAME -maxdepth 1 -ctime +$DAYS -exec rm -rf {} \;

exit 0