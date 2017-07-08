#!/bin/bash

set -e

# TODO replace by sudo
function run_as {
    if [ $# -lt 3 ] ; then 
        echo too few arguments \'$*\' >&2
        exit 2
    fi

    local USER=$1
    shift
    local GROUP=$1
    shift
    local COMMAND_AND_ARGS=$*
    su -s /bin/bash -c "$COMMAND_AND_ARGS" -g $GROUP $USER
}

function wait_for_mysql {
    while ! mysql <<< "" ; do
        sleep 1;
    done;
}

# relies on fact that the docker image has a marker file `volume-not-attached` in checked dir
# argument 1: path to dir to check
function check_volume_attached {
    local VOLUME_DIR=$(realpath $1)
    if [ -e ${VOLUME_DIR}/volume-not-attached ] ; then
        echo volume $VOLUME_DIR not attached
        exit 2;
    fi
}

# TODO check volume rights

check_volume_attached /var/www/html
check_volume_attached /var/lib/mysql

rm -rf /run/httpd/* /tmp/httpd*

MARIADB_DATADIR=/var/lib/mysql

if [ ! -d $MARIADB_DATADIR ] || [ ! "$(ls -A $MARIADB_DATADIR )" ] ; then

    echo initializing database

    if [ -z ${DB_PASSWORD+x} ] ; then # if varialbe DB_PASSWORD is not set
        echo variable DB_PASSWORD is not set >&2
        exit 2
    fi

    if [ -z ${DB_USER} ] ; then # if varialbe DB_USER is empty
        echo variable DB_USER is empty >&2
        exit 2
    fi

    [ "$(pgrep mysqld)" ] && mysqladmin shutdown

    run_as mysql mysql /usr/bin/mysql_install_db --datadir=$MARIADB_DATADIR
    run_as mysql mysql /usr/libexec/mysqld &
    echo mariadb started
    wait_for_mysql

    # mariadb treats '%' and localhost hosts differently
    mysql <<EOF
        CREATE USER ${DB_USER};
        GRANT ALL ON *.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL ON *.* TO '${DB_USER}'@localhost IDENTIFIED BY '${DB_PASSWORD}';
        FLUSH PRIVILEGES;
EOF

    if [ $DB_NAME ] ; then
        mysql <<< "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
    fi

#     /usr/bin/mysql_secure_installation <<EOF

# y
# ${DB_PASSWORD}
# ${DB_PASSWORD}
# y
# y
# y
# y
# EOF

    # mysqladmin -p${DB_PASSWORD} shutdown
    echo mariadb will be terminated
    mysqladmin shutdown
else
    echo database already initialized
fi

/usr/sbin/httpd -D FOREGROUND &
# no feature of mysqld_safe is required
run_as mysql mysql /usr/libexec/mysqld &
echo successfully started!
wait 