#!/bin/sh
# Slave replication auto recovery and alert
# Star Dot Hosting 2012

currentmonth=`date "+%Y-%m-%d"`
lock_file=/tmp/slave_alert.lck

echo "MySQL Replication Check Script" > /var/log/replication_check.log 2>&1
echo "------------------------------" >> /var/log/replication_check.log 2>&1
echo "$currentmonth" >> /var/log/replication_check.log 2>&1
echo "" >> /var/log/replication_check.log 2>&1


# Check if lock file exists
if [ -f $lock_file ];
then
        echo "Lock file exists! Possible conflict!" >> /var/log/replication_check.log 2>&1
        mail_alert
        exit 1
else
        touch $lock_file
fi

# Fix slave
function fix_replication () {
        mysql -u root --password="XXXXX" -Bse "stop slave" >> /var/log/replication_check.log 2>&1
        if [ "$?" -eq 0 ];
        then
                echo "Stop slave succeeded..." >> /var/log/replication_check.log 2>&1
        else
                echo "Slave recover function failed" >> /var/log/replication_check.log 2>&1
                mail_alert
                exit 1
        fi
        mysql -u root --password="XXXXX" -Bse "reset slave" >> /var/log/replication_check.log 2>&1
        if [ "$?" -eq 0 ];
        then
                echo "Reset slave succeeded..." >> /var/log/replication_check.log 2>&1
        else
                echo "Slave recover function failed" >> /var/log/replication_check.log 2>&1
                mail_alert

                exit 1
        fi
        mysql -u root --password="XXXXX" -Bse "slave start" >> /var/log/replication_check.log 2>&1
        if [ "$?" -eq 0 ];
        then
                echo "Slave start succeeded." >> /var/log/replication_check.log 2>&1
        else
                echo "Slave recover function failed" >> /var/log/replication_check.log 2>&1
                mail_alert
                exit 1
        fi
}


# Alert function
function mail_alert () {
        cat /var/log/replication_check.log | mail -s "Replication check errors!" kkutzko@n49.com
}


# Check if Slave is running properly
Slave_IO_Running=`mysql -u root --password="XXXXX" -Bse "show slave status\G" | grep Slave_IO_Running | awk '{ print $2 }'`
Slave_SQL_Running=`mysql -u root --password="XXXXX" -Bse "show slave status\G" | grep Slave_SQL_Running | awk '{ print $2 }'`
Last_error=`mysql -u root --password="XXXXX" -Bse "show slave status\G" | grep Last_error | awk -F \: '{ print $2 }'`


# If no values are returned, slave is not running
if [ -z $Slave_IO_Running -o -z $Slave_SQL_Running ];
then
        echo "Replication is not configured or you do not have the required access to MySQL"
        exit 1
fi

# If everythings running, remove lockfile if it exists and exit
if [ $Slave_IO_Running == 'Yes' ] && [ $Slave_SQL_Running == 'Yes' ];
then
        rm $lock_file
        echo "Replication slave is running" >> /var/log/replication_check.log 2>&1
        echo "Removed Alert Lock" >> /var/log/replication_check.log 2>&1
elif [ $Slave_SQL_Running == 'No' ] || [ $Slave_IO_Running == 'No' ];
then
        echo "SQL thread not running on server `hostname -s`!" >> /var/log/replication_check.log 2>&1
        echo "Last Error:" $Last_error >> /var/log/replication_check.log 2>&1
        fix_replication
        mail_alert
        rm $lock_file
fi

echo "Script complete!" >> /var/log/replication_check.log 2>&1
exit 0
