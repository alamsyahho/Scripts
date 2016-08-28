#!/bin/bash
CONTAINER=/media/$( echo `hostname` | cut -d"." -f1 )
EMAILTO=serveralert@example.com
DATE=`/bin/date +'%Y%m%d'`

eval mount | grep s3fs > /dev/null 2>&1

if [ $? -eq 0 ] ; then

        /bin/mkdir $CONTAINER/$DATE

        # Copy /home
        /usr/bin/rsync -auv --exclude-from=/root/exclude_list /home $CONTAINER/$DATE/

        # Copy /usr/local
        /usr/bin/rsync -auv /usr/local $CONTAINER/$DATE/

        # Copy /etc
        /usr/bin/rsync -auv /etc $CONTAINER/$DATE/

        # Copy /cron
        /usr/bin/rsync -auv /var/spool/cron $CONTAINER/$DATE/

        echo "$HOSTNAME monthly backup completed."| /bin/mail -s "$HOSTNAME - monthly backup to S3" $EMAILTO
else
        echo "$HOSTNAME monthly backup NOT completed. S3fs NOT mounted"| /bin/mail -s "$HOSTNAME - ERROR monthly backup to S3" $EMAILTO
fi
