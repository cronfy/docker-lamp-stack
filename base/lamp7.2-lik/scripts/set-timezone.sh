#!/usr/bin/env bash

AREA=$1
CITY=$2

# THIS https://stackoverflow.com/a/20693661/1775065
# AND THIS! https://stackoverflow.com/a/42344810/1775065
echo "tzdata tzdata/Areas select $AREA" > /root/preseed.txt &&
    echo "tzdata tzdata/Zones/$AREA select $CITY" >> /root/preseed.txt &&
    ln -fs "/usr/share/zoneinfo/$AREA/$CITY" /etc/localtime &&
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true &&
    debconf-set-selections /root/preseed.txt && dpkg-reconfigure --frontend noninteractive tzdata
