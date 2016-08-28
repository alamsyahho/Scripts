#!/bin/bash

# Script to check bandwidth usage via vnstat, to run as cron daily
# eg: 55 23 * * * /bin/sh /root/vnstat_bw_check.sh

EMAIL="serveralert@example.com serveralert@example2.com"

vnstat_prog=`which vnstat`;
if [ $? -eq 0 ]; then

SIZE=20
RATE="GiB"
LOG="/tmp/vnstat_check.log"
LOG2="/tmp/vnstat_check2.log"

echo "If you received this warning mail, please cross check with the hosting provider on the bandwidth usage." > $LOG;
echo "Additional bandwidth charges may apply!!" >> $LOG;
echo "" >> $LOG;
echo "Servername: $HOSTNAME" >> $LOG;
echo "Date      : `date`" >> $LOG;
echo "--------------------------------------------------------------------" >> $LOG;

/sbin/ip addr show | grep -a1 ether | grep inet | awk '{print $7 OFS "is using" OFS $2}' >> $LOG;

for i in `/sbin/ip addr show | grep -a1 ether | grep inet | awk '{print $7}'`;
        do /usr/bin/vnstat -s -i $i >> $LOG && /usr/bin/vnstat -s -i $i | grep today | awk '{print $5 OFS $6}'> $LOG2;
                if [ `cat $LOG2 | cut -d" " -f1 | cut -d"." -f1` -ge $SIZE ] && [ `cat $LOG2 | cut -d" " -f2 ` == $RATE ]; then
                        cat $LOG | /bin/mail -s "Warning! Server Bandwidth Usage Exceeded Warning Threshold" $EMAIL ;
                else
                        exit;
                fi;
        done;
rm -f $LOG $LOG2;

else
        echo "VNStat package not found while running bandwidth checking script on $HOSTNAME" | /bin/mail -s "Bandwidth Checking Script Error" $EMAIL;
fi;
