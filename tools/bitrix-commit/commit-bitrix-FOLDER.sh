#!/usr/bin/env bash

# modules wizards/bitrix components/bitrix js

FOLDER="$1"

if [ -z "$FOLDER" ] ; then
	echo "Syntax: `basename $0` <folder in bitrix>" >&2
	echo "Example: `basename $0` modules" >&2
	exit 1
fi

function fail() {
	local msg="$1"
	if [ -z "$msg" ] ; then 
		msg="(unknown)"
	fi
	echo " ** Error: $msg" >&2
	exit 1
}

useremail="`git config --global user.email`"
[ -z "$useremail" ] && fail "git useremail not set, run git config --global user.email 'your@email'"

username="`git config --global user.name`"
[ -z "$username" ] && fail "git username not set, run git config --global user.name 'yourname'"

REPO_ROOT=`git rev-parse --show-toplevel`

if [ -z "$REPO_ROOT" ] ; then
	echo " ** Repository root not found, aborting." >&2
	exit 1
fi

cd "$REPO_ROOT"

added="`git diff --cached --name-only`"

if [ -n "$added" ] ; then
	fail "some files already added for commit, please clean this. Aborting."
fi

path="www/bitrix/$FOLDER"

[ -d "$path" ] && [ -x "$path" ] || fail "Directory $path not found or not accessible"

for i in `find $path -maxdepth 1 -mindepth 1 -type d` ; do
	echo " -- Adding $i"

	git add --all $i || fail "add failed"

	added="`git diff --cached --name-only`"
	if [ -z "$added" ] ; then
		echo " -- No changes"
		continue
	fi

	count="`echo "$added" | wc -l`"
	if [ "5000" -lt "$count" ] ; then
		echo " ** Too many files added ($count), probably wrong folder $FOLDER, try deeper path." >&2
		git reset HEAD
		exit 1
	fi

	git commit -m "auto add/modify $i" || fail "commit failed"

	echo " -- Done with $i"
done

