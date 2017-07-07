#!/bin/bash

set -e

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

    [ "$(pgrep mysqld)" ] && mysqladmin shutdown

    run_as mysql mysql /usr/bin/mysql_install_db --datadir=$MARIADB_DATADIR
    run_as mysql mysql /usr/libexec/mysqld &
    echo mariadb started
    wait_for_mysql
    echo mariadb will be terminated
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
    mysqladmin shutdown
else
    echo database already initialized
fi

/usr/sbin/httpd -D FOREGROUND &
# no feature of mysqld_safe is required
run_as mysql mysql /usr/libexec/mysqld &
echo successfully started!
wait 