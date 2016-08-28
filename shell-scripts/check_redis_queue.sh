#!/bin/bash

#########################################################################
# Usage: ./check_redis_queue.sh -H redishost -P redisport -q redisquery -w integer -c integer
#########################################################################
help="\ncheck_redis_queue.sh (c) 2008-2014 GNU GPLv2 licence
Usage: check_redis_queue.sh -H host -P port [-q query] [-w integer] [-c integer]\n
Options:\n-H Hostname or IP of slave server\n-P Port of slave server\n-q redisquery\n-w Number of Queues for Warning status (optional)\n-c Number of Queues for Critical status (optional)"

STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning (not really used)
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin # Set path

for cmd in redis-cli awk grep [
do
 if ! `which ${cmd} &>/dev/null`
 then
  echo "UNKNOWN: This script requires the command '${cmd}' but it does not exist; please check if command exists and PATH is correct"
  exit ${STATE_UNKNOWN}
 fi
done

# Check for people who need help - aren't we all nice ;-)
#########################################################################
if [ "${1}" = "--help" -o "${#}" = "0" ];
        then
        echo -e "${help}";
        exit 1;
fi

# Important given variables
#########################################################################
while getopts "H:P:u:p:q:w:c:h" Input;
do
        case ${Input} in
        H)      host=${OPTARG};;
        P)      port=${OPTARG};;
        u)      user=${OPTARG};;
        p)      password=${OPTARG};;
        q)      query=${OPTARG};;
        w)  warn_queue=${OPTARG};;
        c)  crit_queue=${OPTARG};;
        h)      echo -e "${help}"; exit 1;;
        \?)     echo "Wrong option given. Please use options -H for host, -P for port, -q for query"
                exit 1
                ;;
        esac
done

# Connect to the Redis server and check for informations
#########################################################################
# Check whether all required arguments were passed in
if [ -z "${host}" -o -z "${port}" -o -z "${query}" ];then
        echo -e "${help}"
        exit ${STATE_UNKNOWN}
fi
# Connect to the Redis server and store output in vars
ConnectionResult=`redis-cli -h ${host} -p ${port} ${query} 2>&1`
if [ -z "`echo "${ConnectionResult}"`" ]; then
        echo -e "CRITICAL: Unable to connect to server ${host}:${port}"
        exit ${STATE_CRITICAL}
fi
count=`echo "${ConnectionResult}" | awk '{print $1}'`

# Output of different exit states
#########################################################################
if [ ${count} = "NULL" ]; then
echo "CRITICAL: Redis server seems to be stopped"; exit ${STATE_CRITICAL};
fi

 # Delay thresholds are set
 if [[ -n ${warn_queue} ]] && [[ -n ${crit_queue} ]]; then
  if ! [[ ${warn_queue} -gt 0 ]]; then echo "Warning threshold must be a valid integer greater than 0"; exit $STATE_UNKNOWN; fi
  if ! [[ ${crit_queue} -gt 0 ]]; then echo "Warning threshold must be a valid integer greater than 0"; exit $STATE_UNKNOWN; fi
  if [[ -z ${warn_queue} ]] || [[ -z ${crit_queue} ]]; then echo "Both warning and critical thresholds must be set"; exit $STATE_UNKNOWN; fi
  if [[ ${warn_queue} -gt ${crit_queue} ]]; then echo "Warning threshold cannot be greater than critical"; exit $STATE_UNKNOWN; fi

  if [[ ${count} -ge ${crit_queue} ]]
  then echo "CRITICAL: ${count} queues"; exit ${STATE_CRITICAL}
  elif [[ ${count} -ge ${warn_queue} ]]
  then echo "WARNING: ${count} queues"; exit ${STATE_WARNING}
  else echo "OK: ${count} queues"; exit ${STATE_OK};
  fi
 else
 # Without delay thresholds
 echo "OK: ${count} queues"
 exit ${STATE_OK};
 fi


echo "UNKNOWN: should never reach this part"
exit ${STATE_UNKNOWN}
