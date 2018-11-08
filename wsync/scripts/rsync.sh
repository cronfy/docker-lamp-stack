#!/usr/bin/env bash

INITIAL=false
LITE=false

while true ; do
	case "$1" in
		--lite)
			LITE=true
			shift
			;;
		--initial)
			INITIAL=true
			shift
			;;
		*)
			break
			;;
	esac
done

SERVER="$1"
WWWROOT="$2"

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo "Syntax: `basename $0` <remote_host> <remote_document_root> [local_dir] " >&2
	exit 1
fi

# add trailing slash
WWWROOT=$WWWROOT/

if [ -n "$3" ] ; then
	TARGET_DIR="$3/"
else 
	# add trailing slash
	TARGET_DIR=./`basename $WWWROOT`/
fi

# если это просто обновление существующего кода (по умолчанию),
# то не обновляем конфиги
EXCLUDE_CONF="--exclude='bitrix/.settings.php' --exclude='bitrix/php_interface/dbconn.php' --exclude='.htaccess'"

if [ 'true' = "$INITIAL" ] ; then
	# если это первый rsync, то загружаем конфиги
	EXCLUDE_CONF=""
fi

if [ "$LITE" = "true" ] ; then
	echo -e "\n\n\nINITIAL MODE\n\n\n"
	sleep 1
	#
	# INITIAL FAST EXPLORE
	#

	# первая часть exlude для ускорения на первом этапе, чтобы просто увидеть все, что скачается, и при необходимости
	# добавить правки во вторую часть

	# вторая часть exclude - исключение лишнего

	# eval: https://stackoverflow.com/a/21163341/1775065
	eval rsync -av \
            $EXCLUDE_CONF \
	    --exclude='y-market' --exclude='*.jar' --exclude='*.orig' --exclude='*.map' --exclude='*.html' \
	    --exclude='*.svg' --exclude='*.csv' --exclude='*.woff' --exclude='*.eot' --exclude='*.ttf' --exclude='*.woff2' \
	    --exclude='*.cab' --exclude='*.png' --exclude='*.xsd' --exclude='*.jpg' --exclude='*.xml' --exclude='*.gif' \
	    --exclude='*.js' --exclude='*.php' --exclude='*.css' \
	    --exclude='*.jpeg' --exclude='*.otf' --exclude='*.sql' --exclude '*.mp3' \
	    \
	    --exclude=bitrix/managed_cache --exclude=bitrix/html_pages --exclude=bitrix/backup --exclude=bitrix/cache \
	    --exclude=bitrix/catalog_export --exclude=upload --exclude=bitrix/tmp \
	    --exclude='*.log' --exclude='*.zip' --exclude='*.bak'  --exclude='*.tar.gz' --exclude='1_files/' --exclude='2_files/' \
	    $SERVER:$WWWROOT $TARGET_DIR
else 
	echo -e "\n\n\n *** FULL MODE"
	echo " *** INITIAL: $INITIAL"
	echo " *** LITE: $LITE"
	echo " *** DEST: $TARGET_DIR"
	echo -e "\n\n\n"
	sleep 2
	#
	# FULL
	#

	# для финальной загрузки оставляем только вторую часть exclude и добавляем delete для удаления лишнего, которое
	# все-таки успело скачаться

	if [ 'true' = "$INITIAL" ] ; then
		# при первой загрузке удаляем все лишнее
		DELETE="--delete-excluded --delete"
	else
		# при обновлении файлов не удаляем ничего лишнего
		DELETE=
	fi

	# eval: https://stackoverflow.com/a/21163341/1775065
	eval rsync -av \
            $EXCLUDE_CONF $DELETE \
	    --exclude=bitrix/managed_cache --exclude=bitrix/html_pages --exclude=bitrix/backup --exclude=bitrix/cache \
	    --exclude=bitrix/catalog_export --exclude=upload --exclude=bitrix/tmp \
	    --exclude='*.log' --exclude='*.zip' --exclude='*.bak'  --exclude='*.tar.gz' --exclude='1_files/' --exclude='2_files/' \
	    $SERVER:$WWWROOT $TARGET_DIR
fi


