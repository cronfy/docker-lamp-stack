#!/usr/bin/env bash

function executeRemoteCommand() {
	local server="$1" command="$2"
	
	COMMAND_64=`echo "$command" | base64`

	ssh $server "echo '$COMMAND_64' | base64 -d | bash"
}

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
	$1 == quote "host" quote { host = $3 }
	$1 == quote "login" quote { username = $3 }
	$1 == quote "database" quote { dbname = $3 }
	$1 == quote "password" quote { password = $3 }

	END { if (password && username && dbname && host) print  username, password, host, dbname }
'`"

if [ -z "$mysqlCredentials" ] ; then
	echo "Failed to get mysql credentials" >&2
	exit 1
fi

# данные приходят с кавычками вокруг, т. е. в виде: 'someuser' 'somepwd' 'somehost' 'somedb'
# кавычки как правило одинарные, потому что так Битрикс генерит .settings.php, ну и awk'шный скрипт
# с другими работать не сможет.
# Так что КАВЫЧКИ ТОЧНО ЕСТЬ, и они одинарные.
# eval - чтобы они раскрылись в переменные  без кавычек, т. е. в $1 будет password, а не 'password'
eval set -- $mysqlCredentials

username="$1"
password="$2"
host="$3"
dbname="$4"

# Список известных больших таблиц, которые не нужно копировать на локалку
KNOWN_BIG_TABLES="b_kdaimportexcel_profile_exec_stat b_event_log"

# Оставим из них только те, что реально есть на сервере, чтобы не было ошибок mysqldump вида 'unknown table'
COMMAND="{ mysql -u '$username' -p'$password' -h '$host' -e 'show tables' -N '$dbname'; } | tee"
SERVER_TABLES="`executeRemoteCommand "$SERVER" "$COMMAND"`"
EXISTING_BIG_TABLES_LIST=""
EXISTING_BIG_TABLES_IGNORE=""
for table in $KNOWN_BIG_TABLES ; do
	if ! echo "$SERVER_TABLES" | grep -q "^$table$" ; then
		continue
	fi

	EXISTING_BIG_TABLES_LIST="$EXISTING_BIG_TABLES_LIST $table"
	EXISTING_BIG_TABLES_IGNORE="$KNOWN_BIG_TABLES_IGNORE --ignore-table=$dbname.$table"
done

echo "Skipping big tables: $EXISTING_BIG_TABLES_LIST" >&2


# Дамп

COMMAND="{ mysqldump -u '$username' -p'$password' -h '$host' '$dbname' $EXISTING_BIG_TABLES_IGNORE ; mysqldump -u '$username' -p'$password' -h '$host' --no-data '$dbname' $EXISTING_BIG_TABLES_LIST ; } | gzip"

executeRemoteCommand "$SERVER" "$COMMAND"

