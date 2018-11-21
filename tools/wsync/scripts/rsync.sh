#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

INITIAL=false
LITE=false
IBLOCKS=false
HELP=false

POS=0
while [ $# -gt 0 ]; do
	case "$1" in
		--lite)
			LITE=true
			shift
			;;
		--initial)
			INITIAL=true
			shift
			;;
		--iblocks)
			IBLOCKS=true
			shift
			;;
		--help)
			HELP=true
			shift
			;;
		*)
			POS=$((POS + 1))
			case $POS in
				1)
					SERVER="$1"
					;;
				2)
					WWWROOT="$1"
					;;
				3)
					TARGET_DIR="$1"
					;;
			esac
			shift
			;;
	esac
done


if [ -z "$WWWROOT" ] || [ -z "$SERVER" ] ; then
	HELP=true
fi

if [ "$HELP" = "true" ] ; then
	{
	echo "Syntax: $SCRIPT_NAME [ --lite | --initial ] <remote_host> <remote_document_root> [local_dir] "
	echo ""
	echo "Загружает файлы с remote_host из remote_document_root в local_dir (или в текущую папку)"
	echo ""
        echo "    remote_document_root  - корень сайта на битриксе, например /home/bitrix/www" 
	echo ""
	echo "    --initial  - загрузить .settings.php, dbconn.php, .htaccess" 
	echo "    --lite     - загрузить только структуру директорий, не загружать файлы" 
	echo ""
	} >&2
	exit 1
fi

if [ "$IBLOCKS" = 'true' ] ; then
	ssh $SERVER "cd $WWWROOT; find ./ -maxdepth 1 -mindepth 1 -name '*.xml' -or -name '*_files' | sed 's=^..=- /=' | sort"
	exit
fi

# add trailing slash
WWWROOT=$WWWROOT/

if [ -n "$TARGET_DIR" ] ; then
	TARGET_DIR="$TARGET_DIR/"
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
		--filter='"merge ./filter.rsync"' \
	    $SERVER:$WWWROOT $TARGET_DIR
fi


