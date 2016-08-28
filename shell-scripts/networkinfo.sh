#/bin/bash
HOSTNAME=`hostname`
LOG=~/networkinfo-$HOSTNAME.log
DATE=`date`

echo "----------------------------------------------------------" >> $LOG;
echo "Server Name = $HOSTNAME" > $LOG;
echo "Date = $DATE" >> $LOG;
echo "----------------------------------------------------------" >> $LOG;
/sbin/ifconfig | grep -B1 "inet" >> $LOG;
echo "----------------------------------------------------------" >> $LOG;
/sbin/route -n >> $LOG;
echo "------------