#!/bin/bash

#
# Script to check and send bandwidth usage report via vnstat
# eg: 55 23 1 * * /bin/sh /root/vnstat_bw_report.sh

EMAIL="serveralert@example.com serveralert@example2.com"
SUBJECT="Monthly Bandwidth Usage Report for `date +"%B %Y"`"

vnstat_prog=`which vnstat`;
if [ $? -eq 0 ]; then

LOG="/tmp/vnstat_report.log"

echo "--------------------------------------------------------------------" > $LOG;
echo "Servername: $HOSTNAME" >> $LOG;
echo "Date      : `date`" >> $LOG;
echo "--------------------------------------------------------------------" >> $LOG;

/sbin/ip addr show | grep -a1 ether | grep inet | awk '{print $7 OFS "is using" OFS $2}' >> $LOG;

echo "" >> $LOG;

for i in `/sbin/ip addr show | grep -a1 ether | grep inet | awk '{print $7}'`;
        do
		/usr/bin/vnstat -d -i $i >> $LOG && /usr/bin/vnstat -w -i $i >> $LOG && /usr/bin/vnstat -m -i $i >> $LOG;
        done;

cat $LOG | mail -s "$SUBJECT" $EMAIL ;
rm -f $LOG;

else
        echo "VNStat package not found while running bandwidth checking script on $HOSTNAME" | mail -s "Bandwidth Report Script Error" $EMAIL;
fi;
