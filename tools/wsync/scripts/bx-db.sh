#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

SERVER="$1"
WWWROOT="$2"

if [ -z "$1" ] || [ -z "$2" ] || [ "--help" = "$1" ] ; then
        {
        echo "Syntax: $SCRIPT_NAME <remote_host> <remote_document_root>"
        echo ""
        echo "Дампит базу bitrix с remote_host и выводит дамп в stdout. Настройки подключения определяет сам по remote_document_root"
        echo ""
        echo "    remote_document_root  - корень сайта на битриксе, например /home/bitrix/www" 
        echo ""
        } >&2

        exit 1
fi

if [ -t 1 ] ; then
	echo "You must redirect output to file, I will echo dump.sql.gz" >&2
	exit 1
fi

mysqlCredentials="`ssh $SERVER cat $WWWROOT/bitrix/.settings.php | awk '
	BEGIN { quote = "'\''"; username = ""; password = ""; dbname = ""; collect = false }
		
	$1 == quote "connections" quote { collect = 1; next; }
	! collect { next }
	$1 == quote "options" quote { exit; }

	{ gsub(/,$/, "", $3) }
	$1 == quote "login" quote { username = $3 }
	$1 == quote "database" quote { dbname = $3 }
	$1 == quote "password" quote { password = $3 }

	END { if (password && username && dbname) print "-u " username " -p" password, dbname }
'`"

if [ -z "$mysqlCredentials" ] ; then
	echo "Failed to get mysql credentials" >&2
	exit 1
fi

echo mysqldump $mysqlCredentials >&2
#ssh $SERVER mysql -e "\"show databases\"" $mysqlCredentials 
ssh $SERVER mysqldump $mysqlCredentials \| gzip

