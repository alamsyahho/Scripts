#! /bin/bash

EMAIL="serveralert@example.com"
TMP_LOG="/tmp/memcached.log"
PATH="/usr/local/bin:/usr/bin:/bin"

#### DO NOT CHANGE THE FOLLOWING SETTINGS #########
DATE=`which date`
KILL=`which kill`
GREP=`which grep`
AWK=`which awk`
PS=`which ps`
SU=`which su`
PHP=`which php`
MEMCACHED=`which memcached`
CAT=`which cat`
MAIL=`which mail`
SLEEP=`which sleep`

###################################################

echo "Start Time: `$DATE`" > $TMP_LOG
echo >> $TMP_LOG

# Get memcache pid and kill it
for x in `$PS ax| $GREP memcached| $GREP -v grep| $AWK '{print $1}'`
do
        echo "Kill memcache with pid $x" >> $TMP_LOG
        $KILL -9 $x
done

echo >> $TMP_LOG
# Start memcache
echo "Starting memcache" >> $TMP_LOG

# Check memcache on port 11211 and start daemon
while [ `ps ax|grep memcache|grep -v grep|grep 11211|wc -l` -eq  0 ]
do
        $MEMCACHED -d -u nobody -p 11211 -t 4 -m 256 -I 4m
done

# Check memcache on port 11222 and start daemon
while [ `ps ax|grep memcache|grep -v grep|grep 11222|wc -l` -eq  0 ]
do
        $MEMCACHED -d -u nobody -p 11222 -t 4 -m 512 -I 4m
done

$PS axu | $GREP memcached | $GREP -v grep >> $TMP_LOG
echo >> $TMP_LOG

# Query to memcache again
$SU - mobgold -c "$PHP ~/www/index.php cli/inventory update" >> $TMP_LOG

echo >> $TMP_LOG
echo "Completed ..." >> $TMP_LOG
echo "End Time  : `$DATE`" >> $TMP_LOG


# Send mail out
$CAT $TMP_LOG | $MAIL -s "$HOSTNAME Memcached daemons restart status" $EMAIL
