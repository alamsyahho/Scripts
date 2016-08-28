#!/bin/bash

start=1
end=24

for ((i=$start;i<=$end;i++)); do
    IP=`ssh root@web${i} "ip -o addr show dev "eth0""| awk '$3 == "inet" {print $4}' | sed -r 's!/.*!!; s!.*\.!!'`
    echo "set web${i} root password to 'Serving Passwd $IP'"
    ssh root@web${i} "
    passwd << EOFPASSWD
Serving Passwd ${IP}
Serving Passwd ${IP}
EOFPASSWD
    "
    echo "Set password done"
    echo
done
