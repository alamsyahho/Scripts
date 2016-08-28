#!/bin/bash

##############################################################################
# Configuration area
##############################################################################

# MySQL user for backup
MYSQLUSER=root


# MySQL password for mysql user
MYSQLPASSWD=randompassword


# Keep old backup $KEEP days
KEEP=1


# Path where you want to put the backup
DESTINATION="/var/mysqlbackup"


# Logfile
LOG="/var/log/`basename "$0"`.log"


# Set path for required tools
PATH=$PATH:/bin:/usr/bin


# Whitespace separated list of all configuration files you want to save
CONFIGS="/etc/my.cnf"





##############################################################################
# Here begins the program
##############################################################################


# Logging function to stdout and logfile
function logging () {

        echo -e "`date +%d.%m.%Y" "%H:%M:%S` $1" | tee -a "$LOG"

}



logging "Starting backup"



# Create destination directory if it doesn't exist and secure it.
umask 0027
test ! -d "$DESTINATION" && mkdir -p "$DESTINATION"
chown root:root "$DESTINATION"



# Create temporary directory
TMPDIR="$DESTINATION/MySQL_`date +%d-%m-%Y_%H-%M-%S`"
mkdir "$TMPDIR"



# Create list with database names
logging "Create list with database names"
DATABASES=`mysql -u $MYSQLUSER --password=$MYSQLPASSWD <<EOF
show databases;
quit
EOF`
DATABASES=`echo $DATABASES | sed -e 's/^Database //'`



# Dump databases
mkdir -p "$TMPDIR/db_exports"
for DB in $DATABASES ; do

        logging "Dumping $DB"
        mysqldump -u $MYSQLUSER -p$MYSQLPASSWD $DB -e -a -c --add-drop-table --add-locks -F -l > "$TMPDIR/db_exports/$DB.sql"

done



# Copy configs
logging "Backup configuration"
mkdir -p "$TMPDIR/configs"
cp -p "$CONFIGS" "$TMPDIR/configs"



# Check if there are binary logs enabled
egrep ^log-bin /etc/my.cnf > /dev/null 2>&1

if [ $? -eq 0 ] ; then

        logging "Copy binary logs"


        # Preparing
        mysql -u $MYSQLUSER -p$MYSQLPASSWD << EOF
        FLUSH TABLES WITH READ LOCK;
        FLUSH LOGS;
EOF

        # Copy binlog
        mkdir -p "$TMPDIR/bin_log"
        BINLOGDIR="`dirname $(egrep ^log-bin /etc/my.cnf | sed -e 's/^.*=//g')`"
        cp -p -r "$BINLOGDIR" "$TMPDIR/bin_log"


        # Remove old binlogs
        mysql -u $MYSQLUSER -p$MYSQLPASSWD <<EOF
        RESET MASTER;
        UNLOCK TABLES;
EOF

fi



# Build tar package
logging "Building tar package"
cd "$DESTINATION"
DIRONLY=`echo $TMPDIR | sed -e 's/^.*\///g'`
tar -zcf "$DIRONLY.tar.gz" "$DIRONLY"



# Remove all backups older than $KEEP days
logging "Removing backups older than $KEEP days"
find "$DESTINATION"/* -type f ! -mtime -$KEEP -exec rm -rf '{}' ';'



# Cleanup
logging "Removing temporary directory"
rm -rf "$TMPDIR"



# Finish
logging "Backup finished\n"



exit 0
