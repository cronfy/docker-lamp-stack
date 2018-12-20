#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

if [ -f '.wsync' ] ; then
	. .wsync

	SERVER="$STAGE_HOST"
	WWWROOT="$STAGE_DOCUMENT_ROOT"
fi

SERVER=${1:-$SERVER}
WWWROOT=${2:-$WWWROOT}

if [ -z "$SERVER" ] || [ -z "$WWWROOT" ] || [ "--help" = "$1" ] ; then
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
	echo "Нужно перенаправить вывод скрипта в какой-либо файл/поток, потому что он выводит дамп БД, сжатый gzip." >&2
	echo "Например:" >&2
	echo "" >&2
	echo "    $SCRIPT_NAME > db.sql.gz" >&2
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

