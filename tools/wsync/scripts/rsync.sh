#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

WRKDIR="`dirname "$0"`"
WRKDIR="`realpath "$WRKDIR"`"

setDefaults() {
	LITE=false
	IBLOCKS=false
	HELP=false
	DRY=false
	EXIT=false
	ECHO=false
	PROTECT_BITRIX_CORE=false
	FORCE_DELETE_FILES_ON_REMOTE=false
	SYNC_LOCAL_SETTINGS=false
	DELETE_FILES=false
	DELETE_EXCLUDED_FILES=false
	FILTERS_LIST=""
	SLEEP=2
	NOT_REAL=false
        OUTPUT_FORMAT="progress"
	FOLDER=
}

setDefaults

# Сначала ищем аргумент --profile, так как он задает настройки по умолчанию
nextIsProfile=false
PROFILE=default
for arg in "$@" ; do
	if [ "$nextIsProfile" == 'true' ] ; then
		PROFILE="$arg"
		break
	fi
	
	case "$arg" in
		--profile)
			nextIsProfile=true
			PROFILE=
		;;
	esac
done

case "$PROFILE" in
	default)
		FILTERS_LIST="bitrix-to-local"
		;;	
	first-time-to-local)
		. "$WRKDIR/profiles/first-time-to-local.sh"
		;;	
	update-without-settings)
		. "$WRKDIR/profiles/update-without-settings.sh"
		;;	
	*)
		file="$WRKDIR/profiles/$PROFILE.sh"
		if [ -f "$file" ] ; then
			. "$file"
		else 
			echo "Unknown profile $PROFILE" >&2
			exit 1
		fi
		;;
esac
# ^^^ конец разбора --profile

if [ -f '.wsync' ] ; then
	. .wsync

	SERVER="$STAGE_HOST"
	WWWROOT="$STAGE_DOCUMENT_ROOT"
fi


POS=0
while [ $# -gt 0 ]; do
	case "$1" in
		--iblocks)
			IBLOCKS=true
			shift
			;;
		--help|help)
			HELP=true
			shift
			if [ "profiles" = "$1" ] ; then
				HELP_PROFILES=true
				shift
			fi	
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
		--force-delete-files-on-remote)
			FORCE_DELETE_FILES_ON_REMOTE=true
			shift
			;;
		--profile)
			# --profile was parsed earlier, skip here
			shift 2
			;;
		--target)
			shift
			TARGET_DIR="$1"
			shift 
			;;
		--folder)
			shift
			FOLDER="$1"
			shift 
			;;
		--verbose|-v)
			OUTPUT_FORMAT="verbose"
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
                                *)       
					echo "Unknown positional argument: $1" >&2
					shift
					HELP=true
					EXIT=true
					;;
			esac

			shift
			;;
	esac

	if [ "$HELP" = "true" ] || [ "$EXIT" = "true" ] ; then
		break
	fi
done


if ([ -z "$WWWROOT" ] || [ -z "$SERVER" ]) && [ "$HELP" != "true" ] ; then
	echo "Не указан remote_host и/или remote_document_root, а также отсутствует файл .wsync. Непонятно, откуда скачивать файлы." >&2
	echo "" >&2
	echo "Для справки запустите:" >&2
	echo "    $SCRIPT_NAME --help" >&2
	echo "" >&2

	exit
fi

if [ "$HELP" = "true" ] ; then
	if [ "$HELP_PROFILES" == 'true' ] ; then
		{
		echo "Профили:"
		echo ""
		for profileFile in "$WRKDIR"/profiles/*.sh ; do
			profileName=`basename "$profileFile" .sh`
			echo "$profileName"
			echo ""

			setDefaults
			PROFILE_DESC=

			. "$profileFile"

			if [ -n "$PROFILE_DESC" ] ; then
				echo "$PROFILE_DESC"
				echo
			fi

			echo -n " * Синхронизирует настройки: "
			[ "$SYNC_LOCAL_SETTINGS" == "true" ] && echo "ДА! (перезапишет пароль к БД и .htaccess!)" || echo "Нет"

			echo -n " * Удаляет отсутствующие в источнике файлы: "
			[ "$DELETE_FILES" == "true" ] && echo "ДА! (удалит всё, чего нет в проекте!)" || echo "Нет"

			echo -n " * Удаляет исключенные из синхронизации файлы: "
			[ "$SYNC_LOCAL_SETTINGS" == "true" ] && echo "ДА! (может уничтожить www/upload, например)" || echo "Нет"
	
			echo
		done
		} >&2
	else 
		{
		echo "Syntax: $SCRIPT_NAME <remote_host> <remote_document_root> [local_dir] [options]"
		echo ""
		echo "Загружает файлы с remote_host из remote_document_root в local_dir (или в текущую папку)"
		echo ""
		echo "    remote_host           - удаленный сервер, с которого загружаем файлы" 
		echo "    remote_document_root  - корень сайта на битриксе, например /home/bitrix/www или /home/hstuser827/domains/site1.ru/public_html" 
		echo ""
		echo "    --help                - эта справка" 
		echo "    --help profiles       - помощь по профилям" 
		echo ""
		echo "    --v, --verbose        - вывод имен передаваемых файлов" 
		echo "    --dry, --dry-run      - не делать реальных изменений, только показать, что произойдет" 
		echo "    --echo                - ничего не делать, только вывести итоговую команду rsync" 
		echo ""
		echo "    --profile ИМЯ         - использовать профиль ИМЯ (доступные имена см. в  --help profiles)" 
		echo "    --folder ИМЯ          - обновить только папку ИМЯ" 
		echo ""
		echo ""
		echo "Если в текущей директории есть файл .wsync, то из него будут взяты настройки подключения:"
		echo ""
 		echo "     переменная STAGE_HOST              - remote_host"
		echo "     переменная STAGE_DOCUMENT_ROOT     - remote_document_root"
		echo ""
		echo ""
		echo "Если в текущей директории есть файл filter.rsync, к аргументам rsync добавляется --filter с этим файлом."
		echo "Пути к файлам в filter.rsync нужно указывать относительно remote_document_root. Например,"
		echo "если remote_document_root это /home/bitrix/www, и нужно исключить /home/bitrix/www/sitemap.xml,"
		echo "то указывать надо как '- /sitemap.xml'"
		echo ""
		echo ""
		echo "Примеры:"
		echo ""
		echo -e "Первая загрузка сайта (только посмотреть, что скачается):\n    $SCRIPT_NAME host /path/to/public_html --profile copy-bitrix-for-dev --dry" 
		echo -e "Первая загрузка сайта (реально скачать):\n    $SCRIPT_NAME host /path/to/public_html --profile copy-bitrix-for-dev" 
		echo -e "Обновление папки bitrix:\n    $SCRIPT_NAME host /path/to/public_html --profile"
		echo -e "Скачать upload:\n    $SCRIPT_NAME host /path/to/public_html --profile copy-bitrix --folder upload" 
		echo ""
		} >&2
	fi
	exit 1
fi

if [ "$EXIT" = "true" ] ; then
	exit 1
fi

if [ "default"  == "$PROFILE" ] ; then
                {
                        echo "" 
                        echo " ***"
                        echo " *** default profile (or no profile) is DEPRECATED. Set profile explicitly with --profile <profile_name>. You are warned. Continuing."
                        echo " ***"
                        echo ""
                } >&2
                SLEEP=10
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
	TARGET_DIR=./www/
fi

if [ "true" == "$SYNC_LOCAL_SETTINGS"  ] ; then
	: nothing
else
	FILTERS_LIST="$FILTERS_LIST bitrix-local-settings"
fi

if [ "$PROTECT_BITRIX_CORE" = "true" ] ; then
	FILTERS_LIST="$FILTERS_LIST protect-bitrix-core"
fi

if [ "true" == "$DELETE_FILES" ] ; then
	DELETE_ARG="--delete"
	if [ "true" == "$DELETE_EXCLUDED_FILES" ] ; then
		DELETE_ARG="$DELETE_ARG --delete-excluded"
	fi
else
	DELETE_ARG=
fi

THIS_PROJECT_LOCAL_FILTER_ARG=
if [ -e './filter.rsync' ] ; then
	THIS_PROJECT_LOCAL_FILTER_ARG="--filter='merge ./filter.rsync'"
fi

DRY_ARG=
if [ 'true' = "$DRY" ] ; then
	DRY_ARG='--dry-run'
	NOT_REAL=true
fi

ECHO_CMD=
if [ 'true' = "$ECHO" ] ; then
	NOT_REAL=true
	ECHO_CMD=echo
fi



FROM_ARG="$SERVER:$WWWROOT"
TO_ARG="$TARGET_DIR"

FOLDER_FILTER_ARG=
if [ -n "$FOLDER" ] ; then
	FOLDER_FILTER_ARG=" --filter='+ /$FOLDER/' --filter='- /*' "
fi

if [ -n "$FILTERS_LIST" ] ; then
	FILTERS_LIST_ARG=
	for filter in $FILTERS_LIST ; do
		FILTERS_LIST_ARG="$FILTERS_LIST_ARG --filter='merge $WRKDIR/filter.$filter.rsync' "
	done
else
	FILTERS_LIST_ARG=""
fi

echo " --- PROFILE: $PROFILE"
echo " --- COPY: $FROM_ARG => $TO_ARG"
echo " --- DELETE_FILES: $DELETE_FILES"
echo " --- SYNC LOCAL SETTINGS: $SYNC_LOCAL_SETTINGS"
echo -n " --- Local filter: "
if [ -n "$THIS_PROJECT_LOCAL_FILTER_ARG" ] ; then
	echo "$THIS_PROJECT_LOCAL_FILTER_ARG"
else
	echo none
fi

if [ -n "$FOLDER" ] ; then
	echo " *** FOLDER: $FOLDER"
fi

if [ "true" == "$DRY" ] ; then
	echo " *** MODE: DRY"
fi

echo -e "\n\n\n"

if [ "true" == "$NOT_REAL" ] ; then
	: nothing
else
	sleep $SLEEP || { echo "Sleep error" ; exit 1; }
fi

if [ "$NOT_REAL" = "true" ] ; then
	OUTPUT_FORMAT="verbose"
fi

if [ "$OUTPUT_FORMAT" = "verbose" ] ; then
	OUTPUT_FORMAT_ARG="-v --out-format=\"%n %l\""
else
	OUTPUT_FORMAT_ARG="--info='progress2'"
fi

# rsync использует алгоритм delta-transfer для передачи файлов. Это означает, что если файл изменился
# частично, или вообще не менялся, то rsync синхронизирует его, не передавая его содержимое целиком,
# а только изменения. Поэтому имеет смысл перед началом rsync скопировать на сайт заготовленное ядро
# bitrix, чтобы не нужно было передавать сотни мегабайт исходников Битрикса по сети.

# eval: https://stackoverflow.com/a/21163341/1775065
eval $ECHO_CMD rsync -az \
	$DRY_ARG \
	\
	$DELETE_ARG \
	\
	$FILTERS_LIST_ARG \
	\
	$THIS_PROJECT_LOCAL_FILTER_ARG \
	\
	$FOLDER_FILTER_ARG \
	\
	$OUTPUT_FORMAT_ARG \
	$FROM_ARG $TO_ARG

