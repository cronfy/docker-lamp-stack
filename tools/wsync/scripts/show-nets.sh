#!/usr/bin/env bash

SCRIPT_NAME="${SCRIPT_NAME:-`basename $0`}"

if [ "--help" = "$1" ] ; then
        {
        echo "Syntax: $SCRIPT_NAME"
        echo ""
        echo "Показывает список сетей docker."
        echo ""
        } >&2
        exit 1
fi

# sort: https://unix.stackexchange.com/a/52819/49860
docker network ls --format '{{ .ID }}' | 
	xargs docker network inspect --format '{{ .Name }} {{ range .IPAM.Config }}{{.Subnet}}{{end}}' | 
	awk ' 
		BEGIN { sep = FS } 
		{ printf $0 " " ; FS="."; $0 = $2 ; gsub(/.[0-9]+$/, "", $4); print $1, $2, $3, $4 ; FS = sep ;  print "" } ' |
	sort -g -k3,3 -k4,4 -k5,5 -k6,6 | 
	awk ' $2 { print $1, $2}' | 
	column -t

