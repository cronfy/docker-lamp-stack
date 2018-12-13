#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

case $1 in
	.wsync)
		echo ".wsync - специальный файл в корне проекта, который описывает пути и серверы,"
		echo "чтобы не нужно было постоянно вводить их в качестве аргументов."
		echo "Пример файла:"
		echo "
STAGE_HOST=itweb
STAGE_PROJECT_ROOT=/home/bitrix/projects/eshop.test-itweb.ru/project
STAGE_DOCUMENT_ROOT=${STAGE_PROJECT_ROOT}/www
"
		;;
	*)
		if [ -n "$1" ] ; then
			echo "Неизвестный раздел помощи."
			echo
		fi

		echo "Wsync синхронизирует сайты между удаленным хостингом и локальной копией."
		echo "Разделы помощи:"
		echo " - .wsync"
		;;
esac

