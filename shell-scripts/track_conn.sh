#!/bin/bash
STORE_DIR="/var/log/track_conn"
TODAY=`date +"%Y%m%d"`
LOG_FILE="${STORE_DIR}/${TODAY}.log"
MAX_CONN="cat /proc/sys/net/ipv4/netfilter/ip_conntrack_max"
TOTAL_CONN="cat /proc/sys/net/ipv4/netfilter/ip_conntrack_count"
TOTAL_TCP_CONN="grep -c ^tcp /proc/net/ip_conntrack"
TOTAL_UDP_CONN="grep -c ^udp /proc/net/ip_conntrack"

if [ ! -d ${STORE_DIR} ] ; then
        mkdir ${STORE_DIR}
fi

if [ ! -f ${LOG_FILE} ] ; then
        touch ${LOG_FILE}
fi

echo -e "===============`date +%T`===============\nThe current total number of connections ( TCP + UDP ) is `${TOTAL_CONN}` out of a MAX of `${MAX_CONN}`\nThe total number of TCP connections is `${TOTAL_TCP_CONN}` \
\nThe total number of UDP connections is `${TOTAL_UDP_CONN}`\n" >> ${LOG_FILE}

#Find files which were last modified more than 60 minutes ago
for i in `find ${STORE_DIR} -type f -mmin +60`
do
	# When && is used. rm command is only executed if the previous command exited with a zero exit code . Means no error.
        cat ${i} |  mail -s "Netfilter Value Monitoring for ${HOSTNAME}" syssup@example.com && rm -f ${i}
done

#*/10 * * * * /root/track_conn.sh > /dev/null 2>&1
