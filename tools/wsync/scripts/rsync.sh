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
UPLOAD=false
FORCE_DELETE_FILES_ON_REMOTE=false
SYNC_LOCAL_SETTINGS=false
DELETE_FILES=false
FILTERS_LIST=""
SLEEP=2


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
		{
			echo "" 
			echo " ***"
			echo " *** default profile (or no profile) is DEPRECATED. Set profile explicitly with --profile <profile_name>. You are warned. Continuing."
			echo " ***"
			echo ""
		} >&2
		SLEEP=10

		FILTERS_LIST="bitrix-to-local"
		;;	
	first-time-to-local)
		FILTERS_LIST="bitrix-to-local"
		SYNC_LOCAL_SETTINGS=true
		DELETE_FILES=true
		;;	
	first-time-to-stage)
		UPLOAD=true
		SYNC_LOCAL_SETTINGS=true
		FILTERS_LIST="common-dev-test-var-files bitrix-tmp-cache-files"
		;;	
	*)
		echo "Unknown profile $PROFILE" >&2
		exit 1
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
		--force-delete-files-on-remote)
			FORCE_DELETE_FILES_ON_REMOTE=true
			shift
			;;
		--up|--upload)
			UPLOAD=true
			shift
			;;
		--profile)
			# --profile was parsed earlier, skip here
			shift 2
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
fi
# ^^


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

if [ "true" == "$SYNC_LOCAL_SETTINGS"  ] ; then
	: nothing
else
	FILTERS_LIST="$FILTERS_LIST bitrix-local-settings"
fi

if [ "$PROTECT_BITRIX_CORE" = "true" ] ; then
	FILTERS_LIST="$FILTERS_LIST protect-bitrix-core"
fi

if [ "true" == "$DELETE_FILES" ] ; then
	DELETE_ARG="--delete-excluded --delete"
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
fi

ECHO_CMD=
if [ 'true' = "$ECHO" ] ; then
	ECHO_CMD=echo
fi



if [ "$UPLOAD" == 'true' ] ; then
	FROM_ARG="$TARGET_DIR"
	TO_ARG="$SERVER:$WWWROOT"
else 
        FROM_ARG="$SERVER:$WWWROOT"
        TO_ARG="$TARGET_DIR"
fi

if [ -n "$FILTERS_LIST" ] ; then
	FILTERS_LIST_ARG=
	for filter in $FILTERS_LIST ; do
		FILTERS_LIST_ARG="$FILTERS_LIST_ARG --filter='merge $WRKDIR/filter.$filter.rsync' "
	done
else
	FILTERS_LIST_ARG=""
fi

if [ "$UPLOAD" == "true" ] ; then
	if [ "$DELETE_FILES" == "true" ] ; then
		echo "DELETING ON UPLOAD!!"
		echo "Not implemented, exiting."
		exit 1
	fi
fi

echo " --- PROFILE: $PROFILE"
echo " --- COPY: $FROM_ARG => $TO_ARG"
echo " --- DELETE_FILES: $DELETE_FILES"
echo " --- SYNC LOCAL SETTINGS: $SYNC_LOCAL_SETTINGS"

if [ "true" == "$DRY" ] ; then
	echo " *** MODE: DRY"
fi

echo -e "\n\n\n"

if [ "true" == "$DRY" ] || [ "true" == "$ECHO" ] ; then
	: nothing
else
	sleep $SLEEP || { echo "Sleep error" ; exit 1; }
fi

# eval: https://stackoverflow.com/a/21163341/1775065
eval $ECHO_CMD rsync -avz \
	$DRY_ARG \
	\
	$DELETE_ARG \
	\
	$FILTERS_LIST_ARG \
	\
	$THIS_PROJECT_LOCAL_FILTER_ARG \
	--out-format=\"%n %l\" \
	$FROM_ARG $TO_ARG

