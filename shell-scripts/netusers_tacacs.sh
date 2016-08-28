#!/bin/bash
# Author: Alamsyah
# Revision Date: 20140421
# Version: 1.4
# 1.0 : Beta Script for auto adding AD user to tacacs configuration
# 1.1 : Add auto removal of user not listed in AD
# 1.2 : Check if file is modified, if true will restart tac_plus service
# 1.3 : Fix bug with sed loop and delete
# 1.4 : Add admin and operator auto add script

LDAP_SERVER="ldap://1.1.1.1:389"
DN_NETADMIN="cn=Netadmin,ou=Group,dc=exampleorg,dc=co,dc=id"
DN_NETOPERATOR="cn=Netoperator,ou=Group,dc=exampleorg,dc=co,dc=id"
DN_CSF="dc=exampleorg,dc=co,dc=id"
ADMIN_TACACS="CSF\admin.tacacs"
PWD_ADMIN_TACACS="Test1234!"
CONF_TACACS="/etc/tac_plus.conf"
INIT_TACACS="/etc/init.d/tac_plus"

#------------ DO NOT CHANGE THE FOLLOWING SETTINGS -------------------

LDAPSEARCH=`which ldapsearch`
GREP=`which grep`
EGREP=`which egrep`
CUT=`which cut`
AWK=`which awk`
SED=`which sed`
WC=`which wc`
CAT=`which cat`
FIND=`which find`

#---------------------------------------------------------------------

NO_OF_NETADMIN=(`$LDAPSEARCH -LLL -H $LDAP_SERVER -b $DN_NETADMIN -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS | $GREP member | $EGREP -v Tacacs | $CUT -c 9- | $WC -l`)
for (( x=1; x<=$NO_OF_NETADMIN; x++ ))
do
        DN_USER=`$LDAPSEARCH -LLL -H $LDAP_SERVER -b $DN_NETADMIN -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS | $GREP member | $EGREP -v Tacacs | $CUT -c 9- | $AWK -v x=$x 'NR==x {print}'`
        NAME_NETADMIN=`$LDAPSEARCH -LLL -H $LDAP_SERVER -b "$DN_USER" -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS | $GREP sAMAccountName | $AWK '{print $2}'`

        if ! $GREP -q $NAME_NETADMIN $CONF_TACACS;
        then
                $SED -i "/# Netadmin user/a user = $NAME_NETADMIN { login = PAM member = netadmin }" $CONF_TACACS
                INIT_RESTART=1
        fi
done

NO_OF_NETOPERATOR=(`$LDAPSEARCH -LLL -H $LDAP_SERVER -b $DN_NETOPERATOR -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS | $GREP member | $EGREP -v Tacacs | $CUT -c 9- | $WC -l`)
for (( y=1; y<=$NO_OF_NETOPERATOR; y++ ))
do
        DN_USER=`$LDAPSEARCH -LLL -H $LDAP_SERVER -b $DN_NETOPERATOR -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS | $GREP member | $EGREP -v Tacacs | $CUT -c 9- | $AWK -v y=$y 'NR==y {print}'`
        NAME_NETOPERATOR=`$LDAPSEARCH -LLL -H $LDAP_SERVER -b "$DN_USER" -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS | $GREP sAMAccountName | $AWK '{print $2}'`

        if ! $GREP -q $NAME_NETOPERATOR $CONF_TACACS;
        then
                $SED -i "/# Netoperator user/a user = $NAME_NETOPERATOR { login = PAM member = netoperator }" $CONF_TACACS
                INIT_RESTART=1
        fi
done

# Remove unused user that are not listed on AD
declare -a USER_IN_CONF=(`$CAT $CONF_TACACS | $GREP user | $GREP PAM | $AWK '{print $3}'`)
NO_OF_USER_IN_CONF=(`$CAT $CONF_TACACS | $GREP user | $GREP PAM | $WC -l`)
for (( z=0; z<NO_OF_USER_IN_CONF; z++ ))
do
       if ( ! $LDAPSEARCH -LLL -H $LDAP_SERVER -b "$DN_CSF" -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS "(sAMAccountName=${USER_IN_CONF[$z]})"|$GREP -i $DN_NETADMIN > /dev/null 2>&1) && ( ! $LDAPSEARCH -LLL -H $LDAP_SERVER -b "$DN_CSF" -D $ADMIN_TACACS -w $PWD_ADMIN_TACACS "(sAMAccountName=${USER_IN_CONF[$z]})"|$GREP -i $DN_NETOPERATOR > /dev/null 2>&1);
       then
                $SED -i "/${USER_IN_CONF[$z]}/d" $CONF_TACACS
                INIT_RESTART=1
       fi
done

# Restart tac_plus service if config modified
if [ "$INIT_RESTART" == "1" ];
then
        $INIT_TACACS restart
fi

exit 0
