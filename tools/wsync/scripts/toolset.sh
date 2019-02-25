#!/usr/bin/env bash

function findConfig() {
	local path="`pwd`"

	while [ "$path" != "/" ] ; do
		[ -f "$path/.wsync" ] && echo "$path/.wsync" && return

		path="`dirname "$path"`"
	done

	return 1
}

function includeConfig() {
	local config="`findConfig`"

	if [ -n "$config" ] ; then
		. "$config"
		return
	fi

	return 1
}
