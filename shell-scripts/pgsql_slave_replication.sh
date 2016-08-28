#!/bin/bash

PGSQL_INIT="/etc/init.d/postgresql-9.3"
PGSQL_HOME="/var/lib/pgsql/9.3"
PG_BASEBACKUP=`which pg_basebackup`
MASTER_PGSQL="1.1.1.1"
REPL_USER="replicator"
PGSQL_SHARED_BUFFERS="2GB"
SED=`which sed`


$PGSQL_INIT stop

mv $PGSQL_HOME/data $PGSQL_HOME/backups/data_`date +%Y%m%d%H%M`

sudo -u postgres $PG_BASEBACKUP -X stream -D $PGSQL_HOME/data/ -h $MASTER_PGSQL -U $REPL_USER

$SED -i "/shared_buffers/c\shared_buffers = ${PGSQL_SHARED_BUFFERS}" $PGSQL_HOME/data/postgresql.conf
$SED -i "/^#hot_standby/c\hot_standby = on" $PGSQL_HOME/data/postgresql.conf

sudo -u postgres bash -c "cat > $PGSQL_HOME/data/recovery.conf <<- _EOF1_
standby_mode = 'on'
primary_conninfo = 'host=$MASTER_PGSQL port=5432 user=$REPL_USER'
trigger_file = '/tmp/postgresql.trigger'
_EOF1_
"

$PGSQL_INIT start
