#!/usr/bin/env bash

WRKDIR="`dirname "$0"`"
WRKDIR="`realpath "$WRKDIR"`"

. $WRKDIR/toolset.sh

includeConfig

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

if [ "--help" = "$1" ] || [ -z "$1" ] ; then
        {
        echo "Syntax: $SCRIPT_NAME <url>"
        echo ""
        echo "Скачивает ссылку с сохранением структуры директорий."
	echo "Пример:"
	echo "    $SCRIPT_NAME https://mysite.ru/images/logo.gif"
	echo "Скачает:" 
	echo "	https://mysite.ru/images/logo.gif => ./images/logo.gif"
	echo ""
	echo "Можно указать ссылку без домена, если в конфигурации указаны PROD_DOMAIN и PROD_SCHEME:"
	echo "Пример:"
	echo "    $SCRIPT_NAME /images/logo.gif"
        echo ""
        } >&2
        exit 1
fi

LINK="$1"

if echo "$LINK" | grep -q "^http" ; then
	: absolute url inargument
else
	# relative url in argument
	if [ -n "$PROD_DOMAIN" ] && [ -n "$PROD_SCHEME" ] ; then
		LINK="$PROD_SCHEME://$PROD_DOMAIN${LINK}"
	else
		echo "Дана относительная ссылка, но в конфигурации не заданы PROD_DOMAIN и PROD_SCHEME." >&2
		exit 1
	fi
fi

wget --force-directories --no-host-directories "$LINK"


