#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

WRKDIR="`dirname "$0"`"
WRKDIR="`realpath "$WRKDIR"`"

setDefaults() {
	INITIAL=false
	LITE=false
	IBLOCKS=false
	HELP=false
	DRY=false
	EXIT=false
	ECHO=false
	PROTECT_BITRIX_CORE=false
	FULL=false
	FORCE_DELETE_FILES_ON_REMOTE=false
	SYNC_LOCAL_SETTINGS=false
	DELETE_FILES=false
	DELETE_EXCLUDED_FILES=false
	FILTERS_LIST=""
	SLEEP=2
	NOT_REAL=false
	FOLDER=
}

setDefaults

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

if [ -f '.wsync' ] ; then
	. .wsync

	SERVER="$STAGE_HOST"
	WWWROOT="$STAGE_DOCUMENT_ROOT"
fi


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
	fi
	exit 1
fi

if [ "$EXIT" = "true" ] ; then
	exit 1
fi

# deprecated
if [ 'true' == "$INITIAL" ] ; then
	echo "" >&2
	echo " ***" >&2
	echo " *** --initial is DEPRECATED (use --profile first-time-to-local). You are warned. Continuing." >&2
	echo " ***" >&2
	echo "" >&2
	SLEEP=10

	SYNC_LOCAL_SETTINGS=true
	DELETE_FILES=true
	DELETE_EXCLUDED_FILES=true
fi
# ^^

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
	TARGET_DIR=./`basename $WWWROOT`/
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

# rsync использует алгоритм delta-transfer для передачи файлов. Это означает, что если файл изменился
# частично, или вообще не менялся, то rsync синхронизирует его, не передавая его содержимое целиком,
# а только изменения. Поэтому имеет смысл перед началом rsync скопировать на сайт заготовленное ядро
# bitrix, чтобы не нужно было передавать сотни мегабайт исходников Битрикса по сети.

# eval: https://stackoverflow.com/a/21163341/1775065
eval $ECHO_CMD rsync -avz \
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
	--out-format=\"%n %l\" \
	$FROM_ARG $TO_ARG

