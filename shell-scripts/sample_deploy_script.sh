#!/bin/sh

#
# software deployment script -- run via jenkins or from the command line
#
# usage: deploy.sh server.name
#

SCRIPT=`readlink -f $0`
DIRNAME=`dirname $SCRIPT`
STARTDIR=`dirname $DIRNAME`

##################################################################################
# Get config
##################################################################################

if [ $# -ne 1 ]; then
    echo "usage: $0 servername"
    exit 1
fi
TARGET=$1

cd $STARTDIR
if [ ! -f deploy/$TARGET.conf ]; then
    echo "No config file available: deploy/${TARGET}.conf"
    exit 1
fi

cd $STARTDIR
. deploy/${TARGET}.conf
echo "Deploying to ${TARGETUSER}@${TARGETSERVER}:${TARGETDIR}"

. deploy/sources.conf
echo "Deploying ${SOURCES}"

if [ ! -z $WEBCLUSTERNAME ]; then
    echo "WEBCLUSTERNAME config exist. Using $WEBCLUSTERNAME as root and deploy source"
    TARGET=${WEBCLUSTERNAME}
fi

##################################################################################
# Disable Load Balancer before deployment
##################################################################################

if [ ! -z $LB_HOST ]; then
    echo "Disable $LB_RS(${TARGETSERVER}.example.com) on load balancer before deployment"
    curl -k -silent -u $LB_USER:$LB_PASSWORD https://$LB_HOST/access/disablers?rs=$LB_RS > /dev/null 2>&1
fi

##################################################################################
# Check user account
##################################################################################

cd $STARTDIR
echo "Checking ${TARGETUSER} account and creating if required"
ssh root@${TARGETSERVER} "
    if [ ! -d /home/${TARGETUSER} ]; then
        adduser -c 'Web site owner' -G $WEBGROUP $TARGETUSER
        mkdir -p /home/${TARGETUSER}/logs /home/${TARGETUSER}/.ssh
        cp /root/.ssh/id_dsa /home/${TARGETUSER}/.ssh
        cp /root/.ssh/id_dsa.pub /home/${TARGETUSER}/.ssh
        cp /root/.ssh/authorized_keys /home/${TARGETUSER}/.ssh
        chown -R ${TARGETUSER}:${TARGETUSER} /home/${TARGETUSER}
    fi
"

##################################################################################
# Check APPNAME
##################################################################################

cd ${STARTDIR}/deploy/${TARGET}
if ( grep example.com DOTenv > /dev/null ); then
    APPNAME="sa"
elif ( grep example2.com DOTenv > /dev/null ); then
    APPNAME="sm"
fi

##################################################################################
# Set up deployment directories
##################################################################################

BASEDIR=`dirname $TARGETDIR`
VERSION=`git describe --abbrev=0 --tags --match "v*"|sed -r 's/^(p|v)//'`
echo "Setting up base directories $BASEDIR"
ssh root@${TARGETSERVER} "
    mkdir -p $BASEDIR/$APPNAME-$VERSION
    if [ -d ${TARGETDIR} ]; then
        unlink $TARGETDIR
    fi
    chown -R ${TARGETUSER}:${WEBGROUP} $BASEDIR
    chmod 2775 $BASEDIR
"

echo "Create symlink from $BASEDIR/$APPNAME-$VERSION to $TARGETDIR"
ssh ${TARGETUSER}@${TARGETSERVER} "
    cd $BASEDIR
    ln -s $BASEDIR/$APPNAME-$VERSION $TARGETDIR
    rm -rf \`ls -t | awk 'NR>4'\`
    mkdir -p $TARGETSTORAGE
"

##################################################################################
# Make a backup before starting
##################################################################################

if [ "$TARGETDEPLOYDB" != "new" ]; then
    echo "Backing up existing web files and database on $TARGETSERVER"
    BACKDATE=`date '+%Y%m%d_%H%M'`
    DIR=`basename $BASEDIR`
    BACKDIR=${BACKDATE}_${DIR}
    ssh root@${TARGETSERVER} "
        cd $TARGETDIR
        cd ../..
        mkdir -p backups
        rsync -avrp $TARGETDIR/* backups/$BACKDIR > /dev/null
        if [ "$DBBACKUP" = "yes" ]; then
            mysqldump -u $TARGETDBUSER --password=$TARGETDBPASS -h ${TARGETDBHOST} ${TARGETDBNAME} | gzip > backups/${BACKDATE}_${TARGETDBNAME}.sql.gz
        else
            echo "Database backup disabled on $TARGETSERVER. Change DBBACKUP=yes in your config file to enable"
        fi
    "
fi

##################################################################################
# Deploy web software files
##################################################################################

cd $STARTDIR
echo "Syncing web files to $TARGETDIR"
rsync -vaz --delete $SOURCES ${TARGETUSER}@${TARGETSERVER}:${TARGETDIR} > /dev/null

##################################################################################
# Deploy modified config files
##################################################################################

echo "Deploying config files in ${STARTDIR}/deploy/${TARGETSERVER}"
cd ${STARTDIR}/deploy/${TARGET}
for file in *; do
    TARGETFILE=`echo $file | sed -e 's;+;/;g' -e 's/DOT/\./g'`
    echo "Copying $file to ${TARGETSERVER}:${TARGETDIR}/${TARGETFILE}"
    scp $file ${TARGETUSER}@${TARGETSERVER}:${TARGETDIR}/${TARGETFILE}
done

##################################################################################
# Add APP_KEY from fpm config to DOTenv
##################################################################################

cd ${STARTDIR}/deploy/${TARGET}
if [ ${APPNAME} == "sa" ]; then
    APP_KEY=$(ssh ${TARGETUSER}@${TARGETSERVER} "cat /etc/php-fpm.d/sa.conf |grep SERVERID|sed 's/^.*= //'")
elif [ ${APPNAME} == "sm" ]; then
    APP_KEY=$(ssh ${TARGETUSER}@${TARGETSERVER} "cat /etc/php-fpm.d/sm.conf |grep SERVERID|sed 's/^.*= //'")
fi
ssh ${TARGETUSER}@${TARGETSERVER} "
    if ( ! grep APP_KEY ${TARGETDIR}/.env > /dev/null ); then
        echo "Update ${TARGETDIR}/.env"
        sed -i "/APP_DEBUG/aAPP_KEY=${APP_KEY}" ${TARGETDIR}/.env
    fi
"

##################################################################################
# Install root config files.
##################################################################################

echo "Installing root configuration files on ${TARGETSERVER}"
cd ${STARTDIR}/deploy/root/${TARGET}
for file in *; do
    TARGETFILE=`echo $file | sed 's;+;/;g'`
    echo "Copying $file to ${TARGETSERVER}:/${TARGETFILE}"
    scp $file root@${TARGETSERVER}:/${TARGETFILE}
done

##################################################################################
# Web user config post install
##################################################################################

ssh ${TARGETUSER}@${TARGETSERVER} "
    cd $TARGETDIR
    if [ -f composer.lock ]; then
        composer install --no-interaction
    else
        composer update --no-interaction
    fi
    if [ -f package.json ]; then
        npm install --quiet
    fi
    php artisan route:cache
"

if [ "$?" != "0" ]; then
        echo "Running composer install failed..."
        exit 1
fi

##################################################################################
# Deploy database
##################################################################################

if [ "$TARGETDEPLOYDB" = "new" ]; then
    echo "Creating new database"
    #
    # Drop and recreate the database to ensure it's clean.
    # FIXME: Make it work for remote databases.
    #
    if [ "${TARGETDBHOST}" = "localhost" ] || [ "${TARGETDBHOST}" = "127.0.0.1" ]; then
        ssh root@${TARGETSERVER} "
            cd ${TARGETDIR}
            mysql << EOFDB
            SET FOREIGN_KEY_CHECKS=0;
            DROP DATABASE IF EXISTS ${TARGETDBNAME};
            CREATE DATABASE ${TARGETDBNAME} CHARACTER SET utf8;
            GRANT ALL ON ${TARGETDBNAME}.* TO ${TARGETDBUSER}@localhost IDENTIFIED BY '${TARGETDBPASS}';
EOFDB
        "
    else
        ssh root@${TARGETDBHOST} "
            cd ${TARGETDIR}
            mysql << EOFDB
            SET FOREIGN_KEY_CHECKS=0;
            DROP DATABASE IF EXISTS ${TARGETDBNAME};
            CREATE DATABASE ${TARGETDBNAME} CHARACTER SET utf8;
            GRANT ALL ON ${TARGETDBNAME}.* TO '${TARGETDBUSER}'@'10.%' IDENTIFIED BY '${TARGETDBPASS}';
EOFDB
        "

    fi
fi

##################################################################################
# Run database migration.
##################################################################################

if [ "$TARGETDEPLOYDB" != "none" ]; then
    echo "Running database migration"
    ssh ${TARGETUSER}@${TARGETSERVER} "
        cd ${TARGETDIR}
        sed -i 's/\x27utf8mb4\x27,/\x27utf8\x27, \/\/ edited/g' config/database.php
        sed -i 's/\x27utf8mb4_unicode_ci\x27,/\x27utf8_unicode_ci\x27, \/\/ edited/g' config/database.php
        chmod -R g-w .
        php artisan migrate
    "
fi

##################################################################################
# Run the database seed and create sphinx procedures only on a new database.
##################################################################################

if [ "$TARGETDEPLOYDB" = "new" ]; then
    ssh ${TARGETUSER}@${TARGETSERVER} "
        echo "Running database seed"
        cd ${TARGETDIR}
        php artisan db:seed
        sed -i 's/\x27utf8\x27, \/\/ edited/\x27utf8mb4\x27,/g' config/database.php
        sed -i 's/\x27utf8_unicode_ci\x27, \/\/ edited/\x27utf8mb4_unicode_ci\x27,/g' config/database.php

        #echo "Adding mod_id on profiles table and create trigger"
        #mysql -u ${TARGETDBUSER} --password=$TARGETDBPASS -h ${TARGETDBHOST} #${TARGETDBNAME} << EOFDB
        #ALTER TABLE profiles ADD COLUMN mod_id SMALLINT UNSIGNED NOT NULL DEFAULT '0' #AFTER id, ADD INDEX (mod_id);
        #delimiter //
        #create trigger profile_mod_id before insert on profiles
        #for each row
        #begin
        #    set NEW.mod_id = (
        #        (
        #            (
        #                select max(id) from profiles
        #            ) + 1
        #        ) mod 48
        #    ) + 1;
        #end;//
        #UPDATE profiles SET mod_id = (id MOD 48) + 1;
#EOFDB
    "
fi

##################################################################################
# Configure sphinx server
##################################################################################

if [ ! -z $TARGETSPHINXHOST ]; then
    if [ "${TARGETSPHINXHOST}" = "localhost" ] || [ "${TARGETSPHINXHOST}" = "127.0.0.1" ]; then
        TARGETSPHINXHOST=${TARGETSERVER}
    fi

    cd $STARTDIR
    echo "Updating sphinx DB fields"
    sed -ri "s/(.*sql_host.*=)[^=]*$/\1 ${TARGETDBHOST}/" config/sphinx/indexes/${TARGETDBNAME}.conf
    sed -ri "s/(.*sql_db.*=)[^=]*$/\1 ${TARGETDBNAME}/" config/sphinx/indexes/${TARGETDBNAME}.conf
    sed -ri "s/(.*sql_user.*=)[^=]*$/\1 ${TARGETDBUSER}/" config/sphinx/indexes/${TARGETDBNAME}.conf
    sed -ri "s/(.*sql_pass.*=)[^=]*$/\1 ${TARGETDBPASS}/" config/sphinx/indexes/${TARGETDBNAME}.conf

    echo "Copying sphinx config file to sphinx server on $TARGETSPHINXHOST"
    rsync -avrp config/sphinx/* root@${TARGETSPHINXHOST}:/etc/sphinx > /dev/null

    ssh root@${TARGETSPHINXHOST} "
        if [ ! -d ${TARGETSPHINXDIR}/${TARGETUSER} ]; then
            echo "Setting up sphinx directory"
            mkdir -p ${TARGETSPHINXDIR}/${TARGETUSER}
        fi
        if [ ! -d /usr/local/scripts ]; then
            mkdir -p /usr/local/scripts
        fi
    "

    if [ ${APPNAME} == "sa" ]; then
        echo "Running $APPNAME main indexing"
        ssh root@${TARGETSPHINXHOST} '
            for (( i=1;i<=12;i++ ))
            do
                /usr/bin/indexer --rotate sa_main_${i} > /dev/null 2>&1 &
            done
        '
        echo "Running $APPNAME delta indexing"
        ssh root@${TARGETSPHINXHOST} '
            for (( i=1;i<=6;i++ ))
            do
                /usr/bin/indexer --rotate sa_delta_${i} > /dev/null 2>&1 &
            done
        '

        echo "Setting up cron for sa main and delta indexing"
        CRONMAIN=$'#!/bin/bash\n\n#Sphinx Rotate\nfor (( i=1;i<=12;i++ ))\ndo\n      /usr/bin/indexer --rotate sa_main_${i} &\ndone'
        CRONDELTA=$'#!/bin/bash\n\n#Sphinx Rotate\nfor (( i=1;i<=6;i++ ))\ndo\n      /usr/bin/indexer --rotate sa_delta_${i} &\ndone'

        ssh root@${TARGETSPHINXHOST} "
            echo '$CRONMAIN' > /usr/local/scripts/arrange_main.sh
            echo '$CRONDELTA' > /usr/local/scripts/arrange_delta.sh
            sed -i '3i\#Sphinx Prequeries' /usr/local/scripts/arrange_delta.sh
            sed -i '4i mysql -h ${TARGETDBHOST} -P3306 -u${TARGETDBUSER} -p${TARGETDBPASS} ${TARGETDBNAME} -e \"UPDATE profiles AS P LEFT OUTER JOIN \( SELECT DISTINCT\(profile_id\) FROM lastactivities WHERE updated_at >= DATE_SUB\( NOW\(\), INTERVAL 1 HOUR \) \) AS D ON D.profile_id = P.id SET P.is_online = 0, P.updated_at = NOW\(\) WHERE P.is_online = 1 AND D.profile_id IS NULL\"' /usr/local/scripts/arrange_delta.sh
            sed -i '5i mysql -h ${TARGETDBHOST} -P3306 -u${TARGETDBUSER} -p${TARGETDBPASS} ${TARGETDBNAME} -e \"UPDATE profiles AS P INNER JOIN lastactivities AS LA ON LA.profile_id = P.id AND LA.updated_at >= DATE_SUB\( NOW\(\), INTERVAL 1 HOUR \) SET P.is_online = 1, P.updated_at = NOW\(\) WHERE P.is_online = 0\"' /usr/local/scripts/arrange_delta.sh
            sed -i '6i\\ ' /usr/local/scripts/arrange_delta.sh

            echo '*/5 * * * * root sh /usr/local/scripts/arrange_delta.sh > /dev/null 2>&1' > /etc/cron.d/arrange_sphinx
            echo '0 0 * * * * root sh /usr/local/scripts/arrange_main.sh > /dev/null 2>&1' >> /etc/cron.d/arrange_sphinx
        "

    elif [ ${APPNAME} == "sm" ]; then
        ssh root@${TARGETSPHINXHOST} "
            echo "Running $APPNAME main indexing"
            /usr/bin/indexer --rotate main_example_profiles_sm > /dev/null 2>&1 &
            echo "Running $APPNAME delta indexing"
            /usr/bin/indexer --rotate delta_example_profiles_sm > /dev/null 2>&1 &

            echo "Setting up cron for sm main and delta indexing"
            echo '*/5 * * * * root /usr/bin/indexer --rotate delta_example_profiles_sm > /dev/null 2>&1 &' > /etc/cron.d/million_sphinx
            echo '0 0 * * * * root /usr/bin/indexer --rotate main_example_profiles_sm > /dev/null 2>&1 &' >> /etc/cron.d/million_sphinx
        "
    fi

    ssh root@${TARGETSPHINXHOST} "
        echo "Fixing sphinx permissions"
        chown -R sphinx:sphinx ${TARGETSPHINXDIR}
        chown -R sphinx:sphinx /var/log/sphinx
        chown -R sphinx:sphinx /etc/sphinx

        echo "Restart sphinx"
        service searchd restart > /dev/null 2>&1
    "
fi

##################################################################################
# Update TARGETDIR for dynamic deployment directories
##################################################################################

ssh root@${TARGETSERVER} "
    cd ${TARGETDIR}
    echo "Update targetdir for example-queue"
    sed -i 's|TARGETDIR|${TARGETDIR}|g' app/example-queue.sh
    chmod 755 ${TARGETDIR}/app/example-queue.sh
"

##################################################################################
# Add Route Caching
##################################################################################

echo "Add Route Caching"
ssh root@${TARGETSERVER} "
    cd ${TARGETDIR}
    php artisan route:cache > /dev/null 2>&1
"

##################################################################################
# Reset permissions
##################################################################################

echo "Fixing permissions"
ssh root@${TARGETSERVER} "
    chgrp -R ${WEBGROUP} ${TARGETDIR}
    chmod -R g+rwX ${TARGETDIR}
    find ${TARGETDIR} -type d -exec chmod g+ws {} \;
    chown -R ${WEBUSER} ${TARGETSTORAGE}
    chgrp -R ${WEBGROUP} ${TARGETSTORAGE}
    chmod -R g+rwX ${TARGETSTORAGE}
    chmod -R o-rwx ${TARGETSTORAGE}
    find ${TARGETSTORAGE} -type d -exec chmod g+ws {} \;
"

##################################################################################
# Reload nginx and php-fpm
##################################################################################

echo "Reloading nginx, php-fpm and supervisord"
ssh root@${TARGETSERVER} "
    service nginx reload > /dev/null 2>&1
    service php-fpm reload > /dev/null 2>&1
    service supervisord restart > /dev/null 2>&1
"

##################################################################################
# Enable Load Balancer after deployment
##################################################################################

if [ ! -z $LB_HOST ]; then
    echo "Enable $LB_RS(${TARGETSERVER}.example.com) on load balancer after deployment"
    curl -k -silent -u $LB_USER:$LB_PASSWORD https://$LB_HOST/access/enablers?rs=$LB_RS > /dev/null 2>&1
fi
