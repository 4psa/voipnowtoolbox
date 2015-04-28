#!/bin/bash

INPUT="extensions.csv"
VNPATH="/usr/local/voipnow/bin"

function logger () {
DATE=`date +"%Y-%m-%d %H:%M:%S"`
echo ${DATE} $1
}

if [ -f ${INPUT} ]; then
	logger "File extensions.csv found, using it for data input."
elif [ $# -eq 1 ] && [ -f "$1" ]; then
	logger "Input file $1 supplied as argument, using it for data input."
	INPUT="$1"
else
	logger "Please make sure extensions.csv exists or an input file name is provided as argument to this script."
	exit
fi

LINE=0

EXPECT_PATH="`which expect 1>/dev/null 2>&1`"

if [ "$?" != "0" ]; then
	logger "This script requires expect to be installed. Please install it and retry."
	exit
fi

while IFS=',' read -r ACTION NUMBER PASSWORD PARENTLOGIN LABEL TYPE TEMPLATE
do
LINE=$((LINE+1))
logger "Processing line $LINE"
	case ${ACTION,,} in
		"create")
		CMD="$VNPATH/extension.sh --create ${NUMBER} --parent_login ${PARENTLOGIN} --label ${LABEL}"
		CMD="$CMD --type ${TYPE} --password ${PASSWORD}"
		if [ -n "${TEMPLATE}" ]; then
			CMD="$CMD --extension_template_id ${TEMPLATE}"
		fi
		${CMD} > /dev/null 2>&1
		ERRCODE="$?"
		if [ "${ERRCODE}" !=  "0" ]; then
			logger "Extension ${NUMBER} could not be created, error code: ${ERRCODE}"
		else
			logger "Extension ${NUMBER} successfully created."
		fi
			;;
			
		"update")
		CMD="$VNPATH/extension.sh --update ${NUMBER} --parent_login ${PARENTLOGIN} --label ${LABEL}"
		CMD="$CMD --type ${TYPE} --password ${PASSWORD}"
		if [ -n "${TEMPLATE}" ]; then
			CMD="$CMD --extension_template_id ${TEMPLATE}"
		fi
		${CMD} > /dev/null 2>&1
		ERRCODE="$?"
		if [ "${ERRCODE}" !=  "0" ]; then
			logger "Extension ${NUMBER} could not be updated, error code: ${ERRCODE}"
		else
			logger "Extension ${NUMBER} successfully updated."
		fi
			;;		
			
		"remove")
		echo "Trying to remove ${NUMBER}"
		expect > /dev/null 2>&1 << EOF
		spawn $VNPATH/extension.sh --remove ${NUMBER}
		expect "Do you really want to remove*"
		send yes\r
		expect "Extension removed"
	
EOF
		ERRCODE="$?"
		if [ "${ERRCODE}" !=  "0" ]; then
			logger "Extension ${NUMBER} could not be removed, error code: ${ERRCODE}"
		else
			logger "Extension ${NUMBER} successfully removed."
		fi
			;;		
			
		*)	logger "Line $LINE contains an invalid input, skipping."
			;;
	esac
done < "${INPUT}"
   
