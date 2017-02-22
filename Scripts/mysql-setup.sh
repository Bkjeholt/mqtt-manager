#!/bin/bash -f
# *************************************************************************
# Product    : Home information and control
# Date       : 2016-12-01
# Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
# Contact    : dev@kjeholt.se
# Url        : http://www-dev.kjeholt.se
# Licence    : ---
# -------------------------------------------------------------------------
# File       : mysql-setup/script/setup.sh
# Version    : 1.1.0
# Author     : Bjorn Kjeholt
# *************************************************************************

SQL_ROOT_PATH=/usr/src/app/script/sql/

SQL_SETUP_TABLES_FILE_PATH=create-tables-v1.0.sql
SQL_SETUP_PROCEDURES_FILE_PATH=create-procedures-v1.0.sql
SQL_SETUP_FUNCTIONS_FILE_PATH=create-functions-v1.0.sql
SQL_SETUP_VIEWS_FILE_PATH=create-views-v1.0.sql

MYSQL_USER=root

function CreateDbInfo() {
    SQL_FILE_PATH=${SQL_ROOT_PATH}${1}
    echo "----------------------------------------------------------------------------------"
    echo " SQL File:   ${SQL_FILE_PATH} "
    echo " "

    mysql --user=${MYSQL_USER} \
          --password=${MYSQL_PASSWORD} \
          --host=${MYSQL_IP_ADDR} \
          --port=${MYSQL_PORT_NO} \
          ${MYSQL_DATABASE} < ${SQL_FILE_PATH}
}

 
echo "----------------------------------------------------------------------------------"
echo " Mysql info: "
echo "    IP addr:    ${MYSQL_PORT_3306_TCP_ADDR} "
echo "    IP port:    ${MYSQL_PORT_3306_TCP_PORT} "
echo "    User:       ${MYSQL_USER} "
echo "    Password:   ${MYSQL_ENV_MYSQL_ROOT_PASSWORD} "
echo "    Database:   ${MYSQL_ENV_MYSQL_DATABASE} "
echo " Setup info: "

CreateDbInfo ${SQL_SETUP_TABLES_FILE_PATH}
CreateDbInfo ${SQL_SETUP_PROCEDURES_FILE_PATH}
CreateDbInfo ${SQL_SETUP_FUNCTIONS_FILE_PATH}
CreateDbInfo ${SQL_SETUP_VIEWS_FILE_PATH}

echo "----------------------------------------------------------------------------------"
