#!/bin/bash

if hash jq 2>/dev/null; then
    echo "found jq"
else
    echo "Error jq required not found"
    exit 8
fi

echo "Reading Config"
export CONFIGFILE=./config.json
export $(cat ${CONFIGFILE} | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]")

echo "################################################################"
echo "SOURCE_DATABASE : ${SOURCE_DATABASE}"
echo "SOURCE_USER     : ${SOURCE_USER}"
echo "SOURCE_PASSWORD : ${SOURCE_PASSWORD}"
echo "SOURCE_SCHEMA   : ${SOURCE_SCHEMA}"
echo "SOURCE_TABLE    : ${SOURCE_TABLE}"
echo "################################################################"
echo "TARGET_DATABASE : ${TARGET_DATABASE}"
echo "TARGET_USER     : ${TARGET_USER}"
echo "TARGET_PASSWORD : ${TARGET_PASSWORD}"
echo "TARGET_SCHEMA   : ${TARGET_SCHEMA}"
echo "TARGET_TABLE    : ${TARGET_TABLE}"
echo "################################################################"
echo "OPTION          : ${OPTION}"
echo "################################################################"

WORKSPACE=$(mktemp -d -t ie-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)
chmod 777 ${WORKSPACE}
EXPORTFILE=${WORKSPACE}/${SOURCE_SCHEMA}_${SOURCE_TABLE}.ixf
EXPORTMSGS=${WORKSPACE}/${SOURCE_SCHEMA}_${SOURCE_TABLE}_export.txt
IMPORTFILE=${EXPORTFILE}
IMPORTMSGS=${WORKSPACE}/${TARGET_SCHEMA}_${TARGET_TABLE}_import.txt
echo "################################################################"
echo "WORKSPACE       : ${WORKSPACE}"
echo "EXPORTFILE      : ${EXPORTFILE}"
echo "EXPORTMSGS      : ${EXPORTMSGS}"
echo "IMPORTFILE      : ${IMPORTFILE}"
echo "IMPORTMSGS      : ${IMPORTMSGS}"
echo "################################################################"


echo "# CHECKING THE BASICS BEFORE WE GET STARTED ###################"
# test source connection details
db2 CONNECT TO ${SOURCE_DATABASE} USER ${SOURCE_USER} USING ${SOURCE_PASSWORD}
if [ $? -eq 0 ]
then
  echo "OK : testing connection to ${SOURCE_DATABASE}" 
else
  echo "ERROR testing connection to ${SOURCE_DATABASE}" 
  exit 8
fi

# test target connection details
db2 CONNECT TO ${TARGET_DATABASE} USER ${TARGET_USER} USING ${TARGET_PASSWORD}
if [ $? -eq 0 ]
then
  echo "OK : testing connection to ${TARGET_DATABASE}" 
else
  echo "ERROR : testing connection to ${TARGET_DATABASE}" 
  exit 8
fi

# test source table exists
values=`db2 CONNECT TO ${SOURCE_DATABASE} USER ${SOURCE_USER} USING ${SOURCE_PASSWORD} > /dev/null
db2 -x "select cast(count(*) as integer) from SYSCAT.TABLES where TABSCHEMA = '${SOURCE_SCHEMA}' and TABNAME = '${SOURCE_TABLE}'  WITH UR"
db2 quit > /dev/null
`
#trim whitespace from sql output
values="$(echo -e "${values}" | tr -d '[:space:]')"
if [ "${values}" = "1" ]
  then
    echo "OK : Found source table ${SOURCE_SCHEMA}.${SOURCE_TABLE}"
else
  echo "ERROR : Missing source table ${SOURCE_SCHEMA}.${SOURCE_TABLE}"
  echo "ERROR : Can't export a table that doesn't exist!"
  exit 8
fi


# case 1. Target schema does not exist
values=`db2 CONNECT TO ${TARGET_DATABASE} USER ${TARGET_USER} USING ${TARGET_PASSWORD} > /dev/null
db2 -x "select cast(count(*) as integer) from SYSIBM.SYSSCHEMATA where name = '${TARGET_SCHEMA}' WITH UR"
db2 quit > /dev/null
`
#trim whitespace from sql output
values="$(echo -e "${values}" | tr -d '[:space:]')"
if [ "${values}" = "1" ]
  then
     echo "OK : Target schema ${TARGET_SCHEMA}"
else
  echo "ERROR : Missing target schema ${TARGET_SCHEMA}"
  echo "NYI : create schema"
  echo "NYI : run grants what permissions for what roles"
  exit 8
fi

# case 2. Target table exists
values=`db2 CONNECT TO ${TARGET_DATABASE} USER ${TARGET_USER} USING ${TARGET_PASSWORD} > /dev/null
db2 -x "select cast(count(*) as integer) from SYSCAT.TABLES where TABSCHEMA = '${TARGET_SCHEMA}' and TABNAME = '${TARGET_TABLE}'  WITH UR"
db2 quit > /dev/null
`
#trim whitespace from sql output
values="$(echo -e "${values}" | tr -d '[:space:]')"
if [ "${values}" = "1" ]
  then
     echo "OK : Found target table ${TARGET_TABLE}"
else
  echo "ERROR : Missing target table ${TARGET_TABLE}"
  echo "NYI : create table"
  echo "INFO : Consider running db2look to get the source tables ddl to use in the target"
  echo "  db2look -d ${SOURCE_DATABASE} -w <password> -i ${SOURCE_USER} -u ${SOURCE_USER} -t ${SOURCE_TABLE} -e -dp -noview"
  db2look -d ${SOURCE_DATABASE} -w ${SOURCE_PASSWORD} -i ${SOURCE_USER} -u ${SOURCE_USER} -z ${SOURCE_SCHEMA} -t ${SOURCE_TABLE} -e -dp -noview -o ${WORKSPACE}/source_table.ddl
  cat ${WORKSPACE}/source_table.ddl
  exit 8
fi


echo "################################################################"
echo "################################################################"
echo "INFO : About to connect to source"
db2 CONNECT TO ${SOURCE_DATABASE} USER ${SOURCE_USER} USING ${SOURCE_PASSWORD}
echo "INFO : About to run export"
db2 "export to ${EXPORTFILE} of IXF messages ${EXPORTMSGS} select * from ${SOURCE_SCHEMA}.${SOURCE_TABLE}"
if [ $? -ne 0 ]
then
  echo "ERROR : running export?" >&2
  cat ${EXPORTMSGS} 
  exit 8
fi
cat ${EXPORTMSGS} 

echo "################################################################"
echo "INFO : About to connect to target"
db2 CONNECT TO ${TARGET_DATABASE} USER ${TARGET_USER} USING ${TARGET_PASSWORD}
echo "INFO : About to run load"
loadcmd="load client from ${IMPORTFILE} of IXF messages ${IMPORTMSGS} ${OPTION} into ${TARGET_SCHEMA}.${TARGET_TABLE} STATISTICS NO NONRECOVERABLE"
echo ${loadcmd}
db2 "${loadcmd}"
if [ $? -ne 0 ]
then
  echo "ERROR : running import" >&2
  cat ${IMPORTMSGS}
  exit 8
fi
cat ${IMPORTMSGS}

echo "################################################################"
echo "#  DON'T FORGET TO CLEAN UP WORKSPACE ${WORKSPACE}"
echo "################################################################"