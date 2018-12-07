#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

WRKDIR="`dirname "$0"`"
WRKDIR="`realpath "$WRKDIR"`"

INITIAL=false
LITE=false
IBLOCKS=false
HELP=false
DRY=false
EXIT=false
ECHO=false
PROTECT_BITRIX_CORE=false
FULL=false

POS=0
while [ $# -gt 0 ]; do
	case "$1" in
		--full)
			FULL=true
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
		--dry-run|--dry)
			DRY=true
			shift
			;;
		--echo)
			ECHO=true
			shift
			;;
		--protect-bitrix-core)
			PROTECT_BITRIX_CORE=true
			shift
			;;
		--*)
			echo "Unknown argument: $1" >&2
			shift
			HELP=true
			EXIT=true
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
	echo "    --initial  - загрузить .settings.php, dbconn.php, .htaccess (помимо прочих файлов)" 
	echo "    --full     - загрузить все картинки, upload и прочее, т. е. сделать полную копию сайта" 
	echo ""
	echo "Если в текущей директории есть файл filter.rsync, он подключается через --filter. Пути к файлам"
	echo "нужно указывать относительно remote_document_root. Например, если remote_document_root это"
	echo "/home/bitrix/www, и нужно исключить /home/bitrix/www/sitemap.xml, то указывать надо как"
	echo "- /sitemap.xml"
	echo ""
	} >&2
	exit 1
fi

if [ "$EXIT" = "true" ] ; then
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
EXCLUDE_LOCAL_SETTINGS_ARG="--filter='merge $WRKDIR/filter.bitrix-local-settings.rsync'"

echo " *** INITIAL: $INITIAL"
echo " *** DEST: $TARGET_DIR"
echo -e "\n\n\n"

if [ "true" == "$DRY" ] || [ "true" == "$ECHO" ] ; then
	: nothing
else
	sleep 2
fi

if [ 'true' = "$INITIAL" ] ; then
	# если это первый rsync, то загружаем конфиги
	EXCLUDE_LOCAL_SETTINGS_ARG=""
	# при первой загрузке удаляем все лишнее
	DELETE="--delete-excluded --delete"
else
	# при обновлении файлов не удаляем ничего лишнего
	DELETE=
fi

THIS_PROJECT_LOCAL_FILTER_ARGS=
if [ -e './filter.rsync' ] ; then
	THIS_PROJECT_LOCAL_FILTER_ARGS="--filter='merge ./filter.rsync'"
fi

DRY_ARGS=
if [ 'true' = "$DRY" ] ; then
	DRY_ARGS='--dry-run'
fi

ECHO_CMD=
if [ 'true' = "$ECHO" ] ; then
	ECHO_CMD=echo
fi

PROTECT_BITRIX_CORE_ARG=
if [ "$PROTECT_BITRIX_CORE" = "true" ] ; then
	PROTECT_BITRIX_CORE_ARG="--filter='merge $WRKDIR/filter.protect-bitrix-core.rsync'"
fi

EXCLUDE_BITRIX_TO_LOCAL_ARG="--filter='merge $WRKDIR/filter.bitrix-to-local.rsync'"

# eval: https://stackoverflow.com/a/21163341/1775065
eval $ECHO_CMD rsync -avz \
	$DRY_ARGS \
	\
	$DELETE \
	\
	$PROTECT_BITRIX_CORE_ARG \
	\
	$EXCLUDE_LOCAL_SETTINGS_ARG \
	$EXCLUDE_BITRIX_TO_LOCAL_ARG \
	\
	$THIS_PROJECT_LOCAL_FILTER_ARGS \
	--out-format=\"%n %l\" \
	$SERVER:$WWWROOT $TARGET_DIR

