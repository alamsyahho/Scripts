#!/bin/bash
# Author: Alamsyah
# Revision Date: 20140408
# Version: 1.2

# Server that will be excluded
EXCLUDE_UUID=""

#------------ DO NOT CHANGE THE FOLLOWING SETTINGS -------------------

XE=`which xe`
GREP=`which grep`
EGREP=`which egrep`
AWK=`which awk`
SED=`which sed`
WC=`which wc`

#---------------------------------------------------------------------

declare -a EXCLUDE=(`echo $EXCLUDE_UUID`)
NO_OF_EXCLUDE=(`echo $EXCLUDE_UUID | $WC -w`)

declare -a VM_NAME=(`$XE vm-list | $EGREP -v "Control domain on host:" | $GREP -B 2 "halted" | $GREP name | $AWK '{print $4 $5 $6}'`)
declare -a VM_UUID=(`$XE vm-list | $EGREP -v "Control domain on host:" | $GREP -B 2 "halted" | $GREP uuid | $AWK '{print $5}'`)
NO_OF_VM=`$XE vm-list | $EGREP -v "Control domain on host:" | $EGREP -B 2 "halted" | $EGREP uuid | $WC -l`


for (( x=0; x<$NO_OF_VM; x++ ))
do
        ENABLE_EXCLUDE=0
        for (( y=0; y<$NO_OF_EXCLUDE; y++ ))
        do
                if [ "${VM_UUID[$x]}" == "${EXCLUDE[$y]}" ];
                then
                        ENABLE_EXCLUDE=1
                        break
                fi
        done

        if [ "$ENABLE_EXCLUDE" != "1" ];
        then
                echo "Starting virtual machine" ${VM_NAME[$x]} "with uuid" ${VM_UUID[$x]}
                $XE vm-start uuid=${VM_UUID[$x]}
                sleep 3
        fi

done

exit 0
