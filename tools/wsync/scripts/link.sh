#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

if [ "--help" = "$1" ] || [ -z "$1" ] ; then
        {
        echo "Syntax: $SCRIPT_NAME <url>"
        echo ""
        echo "Скачивает ссылку с сохранением структуры директорий."
	echo "Пример: https://mysite.ru/images/logo.gif => ./images/logo.gif"
        echo ""
        } >&2
        exit 1
fi

LINK="$1"

wget --force-directories --no-host-directories "$LINK"


