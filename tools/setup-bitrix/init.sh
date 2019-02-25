#!/usr/bin/env bash

if [ ! -d "./bitrix" ] || [ ! -f './bitrixsetup.php' ]; then
	echo " ** Необходимо запускать скрипт в корне сайта с установщиком Bitrix" >&2
	exit 1
fi

DB_USER="$1"
DB_NAME="$2"

if [ -z "$DB_USER" ] || [ -z "$DB_NAME" ] ; then
	echo "Syntax: `basename $0` <db_user> <db_name>" >&2
	exit 1
fi

if echo "$DB_USER" | grep -q '[^a-zA-Z0-9_-]' ; then
	echo " ** Имя пользователя содержит недопустимые символы. Допустимы буквы латинского алфавита и цифры." >&2
	exit 1
fi

if echo "$DB_NAME" | grep -q '[^a-zA-Z0-9_-]' ; then
	echo " ** Имя базы данных содержит недопустимые символы. Допустимы буквы латинского алфавита и цифры." >&2
	exit 1
fi

read -s -p "DB password: " DB_PASS
echo

if [ -z "$DB_PASS" ] ; then
	echo " ** Password must not be empty" >&2
	exit 1
fi

if echo "$DB_PASS" | grep -q '[^a-zA-Z0-9_-]' ; then
	echo " ** Пароль содержит недопустимые символы. Допустимы буквы латинского алфавита и цифры." >&2
	exit 1
fi

find ./ -type f -name '*.php' -exec sed -i "s/usernewdevsite/$DB_USER/ ; s/dbnewdevsite/$DB_USER/ ; s/passnewdevsite/$DB_PASS/" {} +

