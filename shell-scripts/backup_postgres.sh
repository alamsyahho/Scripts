#!/bin/bash

DBUSER=postgres
DBNAME=u2p
BACKUPDIR=/var/lib/pgsql/9.3/backups/

#
# Remove core.applogs older than 3 months
#
TIMESTAMP=`date '+%Y%m%d_%H%M'`
pg_dump -U ${DBUSER} ${DBNAME} > ${BACKUPDIR}/${TIMESTAMP}_u2p.sql

#
# Remove core.applogs older than 3 months
#

psql -U ${DBUSER} ${DBNAME} << EOFDB
--
-- Delete core.applogs
--
DELETE FROM core.applogs WHERE created_at < NOW() - INTERVAL '3 month';

EOFDB
