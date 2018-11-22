#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

if [ "--help" = "$1" ] ; then
        {
        echo "Syntax: $SCRIPT_NAME [ --large ]"
        echo ""
        echo "Показывает список неотслеживаемых папок git."
	echo "Запускать надо из корня репозитория."
	echo 
	echo "    --large - показывать только элементы больше 1M (т. е. то, что надо бы добавить в gitignore)"
        echo ""
        } >&2
        exit 1
fi

LARGE=

if [ "--large" = "$1" ] ; then
	LARGE=true
fi

if [ ! -d '.git' ] ; then
	echo ' ** В текущей папке не найден корень репозитория.' >&2
	exit 1 
fi

if [ 'true' = "$LARGE" ] ; then
	FILTER="grep '[MG]'"
else
	FILTER=tee
fi

git status --porcelain | awk ' $1 == "??" { print $2 }' | xargs du -hs | $FILTER

