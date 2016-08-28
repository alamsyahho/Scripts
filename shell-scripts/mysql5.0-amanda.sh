#!/bin/bash

# Change the following to suit you environment
# WARNING DO NOT PUT SPACES IN BETWEEN THE VARIABLES BELOW
# Eg: DEST=/tmp
DEST=`cat /home/example/dest.mysql5.0`
# Eg: DAYS=2
DAYS=`cat /home/example/days.amanda`

##### DO NOT CHANGE THE FOLLOWING SETTINGS #####
AWK=`which awk`
DATE=`which date`
EGREP=`which egrep`
HOSTNAME=`hostname`
LN=`which ln`
MKDIR=`which mkdir`
MYSQL='mysql --default-character-set=utf8 --protocol=tcp -P 3306'
MYSQLDUMP='mysqldump --default-character-set=utf8 --protocol=tcp -P 3306'
MYSQLSHOW=`which mysqlshow`
RM=`which rm`
SED=`which sed`
UNLINK=`which unlink`
WC=`which wc`

declare -a DB=(`$MYSQL -e "show databases;"  |$EGREP -v "(\Database|\information_schema|\lost\+found)"`)
NO_OF_DB=(`$MYSQL -e "show databases;" |$EGREP -v "(\Database|\information_schema|\lost\+found)"|$WC -l`)
TARGET=$DEST/`$DATE +'%Y%m%d'`

echo "Start Time: `$DATE`"

echo
echo "Version Controlling ..."
$RM -rf $DEST/`$DATE -d "-$DAYS day" +'%Y%m%d'`

echo
echo "Dumping MYSQL database ..."
echo
$MKDIR $TARGET
$MYSQLDUMP --no-data --all-databases > $TARGET/$HOSTNAME-DBSTRUCTURE.sql

for (( x = 0 ; x < "$NO_OF_DB" ; x++ ))
do
       declare -a MYISAM_TABLES=(`$MYSQL -e "use ${DB[$x]}; show table status;"|$EGREP MyISAM|$AWK '{print $1}'`)
       declare NO_MYISAM_TABLES=(`$MYSQL -e "use ${DB[$x]}; show table status;"|$EGREP MyISAM|$AWK '{print $1}'|$WC -l`)
       if [ "$NO_MYISAM_TABLES" = "0" ]; then
               echo "You don't have any MYISAM Tables in ${DB[$x]} database"
       else
               $MKDIR $TARGET/${DB[$x]}
               $MYSQLDUMP --no-data ${DB[$x]} > $TARGET/${DB[$x]}/${DB[$x]}-tables-structure.sql
               for (( y = 0 ; y < "$NO_MYISAM_TABLES" ; y++ ))
               do
                       echo "Backing up table ${MYISAM_TABLES[$y]} in ${DB[$x]} database";
                       $MYSQL --quick -e "select * from ${DB[$x]}.${MYISAM_TABLES[$y]};" >> $TARGET/${DB[$x]}/${MYISAM_TABLES[$y]}.sql;
                       $SED -e '1d' $TARGET/${DB[$x]}/${MYISAM_TABLES[$y]}.sql > $TARGET/${DB[$x]}/${MYISAM_TABLES[$y]};
                       $RM -f $TARGET/${DB[$x]}/${MYISAM_TABLES[$y]}.sql;
               done
       fi
       declare -a INNODB_TABLES=(`$MYSQL -e "use ${DB[$x]}; show table status;"|$EGREP InnoDB|$AWK '{print $1}'`)
       declare NO_INNODB_TABLES=(`$MYSQL -e "use ${DB[$x]}; show table status;"|$EGREP InnoDB|$AWK '{print $1}'|$WC -l`)

       if [ "$NO_INNODB_TABLES" = "0" ]; then
               echo "You don't have any InnoDB Tables in ${DB[$x]} database"
       else
#              $MKDIR $TARGET/${DB[$x]}
              $MYSQLDUMP --no-data ${DB[$x]} > $TARGET/${DB[$x]}/${DB[$x]}-tables-structure.sql
              for (( z = 0 ; z < "$NO_INNODB_TABLES" ; z++ ))
              do
                       echo "Backing up table ${INNODB_TABLES[$z]} in ${DB[$x]} database"
                       $MYSQLDUMP --single-transaction ${DB[$x]} ${INNODB_TABLES[$z]}  > $TARGET/${DB[$x]}_${INNODB_TABLES[$z]}.sql
              done
       fi
done

echo Symlinking ...
echo

if [ -L $DEST/latest ]
then
       $UNLINK $DEST/latest
       $LN -s $TARGET $DEST/latest
else
       $LN -s $TARGET $DEST/latest
fi

echo "Completed ..."
echo "End Time  : `$DATE`"
exit 0
