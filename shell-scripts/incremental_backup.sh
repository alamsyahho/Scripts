#!/bin/bash

# Script to run percona full backup once every week and incremental backup on daily basis. When backup file is created, it will upload to S3 folder

################################################################################
################################################################################
################################################################################

BACKUPDIR=/tmp/backup
APP=YourAppName
S3_KEY=YourS3Key
S3_SECRET=YourS3Secret
S3_BUCKET=YourBucketName
S3_REGION=ap-southeast-1

################################################################################

full_backup() {
        echo "cleaning the backup folder..."
        rm -rf $BACKUPDIR
        echo "cleaning done!"
        if [ ! -d $BACKUPDIR ]
        then
                echo "ERROR: $BACKUPDIR does not exists. Creating $BACKUPDIR"
                $MKDIR -p $BACKUPDIR
        fi
        $INNOBACKUPEX --slave-info --no-timestamp $BACKUPDIR_FULL
        date
        echo "Backup done!"
}

incremental_backup()
{
        if [ ! -d $BACKUPDIR_FULL ]
        then
                echo "ERROR: no full backup has been done before. aborting"
                exit -1
        fi

        if [ $DAYOFWEEK -eq 1 ]
        then
                $INNOBACKUPEX --slave-info --no-timestamp --incremental-basedir=$BACKUPDIR_FULL --incremental $BACKUPDIR_INC
        else
                $INNOBACKUPEX --slave-info --no-timestamp --incremental-basedir=$BACKUPDIR_BASEINC --incremental $BACKUPDIR_INC
        fi
}

set_variable()
{
        INNOBACKUPEX=`which innobackupex`
        DATE=`which date`
        TAR=`which tar`
        BASENAME=`which basename`
        MKDIR=`which mkdir`
        DAYOFWEEK=`$DATE +%u`
        DAY_NAME=`$DATE +%A`
        if [ "$DAYOFWEEK" == 7 ];
        then
                FULLBACKUP_DAY=`$DATE +%d`
                FULLBACKUP_MONTH=`$DATE +%m`
                FULLBACKUP_YEAR=`$DATE +%Y`
                BACKUPDIR_FULL="$BACKUPDIR/full"
        else
                FULLBACKUP_DAY=`$DATE +%d -d "- $DAYOFWEEK day"`
                FULLBACKUP_MONTH=`$DATE +%m -d "- $DAYOFWEEK day"`
                FULLBACKUP_YEAR=`$DATE +%Y -d "- $DAYOFWEEK day"`
                BACKUPDIR_FULL="$BACKUPDIR/full"
                BACKUPDIR_INC="$BACKUPDIR/incremental_$DAYOFWEEK"
                BACKUPDIR_BASEINC="$BACKUPDIR/incremental_`$DATE +%u -d '-1 day'`"
        fi
}

compress_backup()
{
        if [ "$DAYOFWEEK" == 7 ];
        then
                COMPRESS_TARGET=$BACKUPDIR_FULL
        else
                COMPRESS_TARGET=$BACKUPDIR_INC
        fi
        $TAR -cjf $COMPRESS_TARGET.tar.bz2 --directory=$BACKUPDIR `$BASENAME $COMPRESS_TARGET`
}

upload_s3()
{
        FILE=`$BASENAME $BACKUPDIR/$COMPRESS_TARGET.tar.bz2`
        S3_DIR="db/$FULLBACKUP_YEAR/$FULLBACKUP_MONTH/$FULLBACKUP_DAY/$APP"
        RESOURCE="/${S3_BUCKET}/${S3_DIR}/${FILE}"
        CONTENTTYPE="application/x-compressed-tar"
        DATEVALUE=`date -R`
        STRINGTOSIGN="PUT\n\n${CONTENTTYPE}\n${DATEVALUE}\n${RESOURCE}"
        SIGNATURE=`echo -en ${STRINGTOSIGN} | openssl sha1 -hmac ${S3_SECRET} -binary | base64`
        curl -X PUT -T "$BACKUPDIR/${FILE}" \
          -H "Host: ${S3_BUCKET}.s3-${S3_REGION}.amazonaws.com" \
          -H "Date: ${DATEVALUE}" \
          -H "Content-Type: ${CONTENTTYPE}" \
          -H "Authorization: AWS ${S3_KEY}:${SIGNATURE}" \
          https://${S3_BUCKET}.s3-${S3_REGION}.amazonaws.com/${S3_DIR}/${FILE}

}

################################################################################

echo "Set up variable"
set_variable

if [ "$DAYOFWEEK" == 7 ];
then
        echo "Today is $DAY_NAME. So we will run full backup"
        full_backup
else
        echo "Today is $DAY_NAME. So we will run incremental backup no.$DAYOFWEEK"
        incremental_backup
fi

echo "Compressing backup before upload to S3"
compress_backup

echo "Uploading file to S3"
upload_s3
echo "Finished uploading to $RESOURCE"
