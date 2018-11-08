#!/usr/bin/env bash

# sort: https://unix.stackexchange.com/a/52819/49860
docker network ls --format '{{ .ID }}' | 
	xargs docker network inspect --format '{{ .Name }} {{ range .IPAM.Config }}{{.Subnet}}{{end}}' | 
	awk ' 
		BEGIN { sep = FS } 
		{ printf $0 " " ; FS="."; $0 = $2 ; gsub(/.[0-9]+$/, "", $4); print $1, $2, $3, $4 ; FS = sep ;  print "" } ' |
	sort -g -k3,3 -k4,4 -k5,5 -k6,6 | 
	awk ' $2 { print $1, $2}' | 
	column -t

