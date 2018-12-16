#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

if [ -f '.wsync' ] ; then
	. .wsync

	SERVER="$STAGE_HOST"
	PROJECT_ROOT="$STAGE_PROJECT_ROOT"
fi

SERVER=${1:-$SERVER}
PROJECT_ROOT=${2:-$PROJECT_ROOT}

if [ -z "$SERVER" ] || [ -z "$PROJECT_ROOT" ] || [ "--help" = "$1" ] ; then
        {
        echo "Syntax: $SCRIPT_NAME <remote_host> <remote_project_dir>"
        echo ""
        echo "Дампит базу проекта cdep с remote_host и выводит дамп в stdout. Настройки подключения определяет сам по remote_project_top_dir"
        echo ""
        echo "    remote_project_dir  - корень проекта cdep, например /home/a029378/projects/als2/project, можно от домашней директории: просто projects/als2/project" 
        echo ""
        } >&2

        exit 1
fi

if [ -t 1 ] ; then
	echo "You must redirect output to file, I will echo dump.sql.gz" >&2
	exit 1
fi

ssh $SERVER ". .bash_profile ; cd $PROJECT_ROOT ; cdep md | gzip"

