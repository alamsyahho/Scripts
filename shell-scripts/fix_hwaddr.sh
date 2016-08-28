#!/bin/bash

CAT=`which cat`
GREP=`which grep`
AWK=`which awk`
SED=`which sed`
TR=`which tr`
MV=`which mv`
UDEV=/etc/udev/rules.d/70-persistent-net.rules
IFCFG=/etc/sysconfig/network-scripts/template_ifcfg-eth0
REAL_IFCFG=/etc/sysconfig/network-scripts/ifcfg-eth0

UDEV_MAC=`$CAT $UDEV | $GREP eth0| $AWK '{print $4}'| $SED 's/ATTR{address}==//' | $SED 's/[",]//g' | $TR '[:lower:]' '[:upper:]'`
IFCFG_MAC=`$CAT $IFCFG|  $GREP HWADDR | $SED 's/HWADDR=//g'`


if [ "$UDEV_MAC" != "$IFCFG_MAC" ];
then
        echo "replace"
        $SED -i "s/$IFCFG_MAC/$UDEV_MAC/" $IFCFG
        $MV $IFCFG $REAL_IFCFG
        /etc/init.d/network restart
fi

exit 0