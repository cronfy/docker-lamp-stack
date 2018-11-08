#!/usr/bin/env bash

PACKAGES="$@"

# apt sometimes downloads packages very slow.
# Even disabling IPv6 does not help.
# Let's speedup download via wget.

apt-get install $PACKAGES -y --print-uris |
    tr -d \' |
    awk '/^http/ {print $1}' > /root/dl.txt &&
    mkdir -p /var/cache/apt/archives &&
    cd /var/cache/apt/archives &&
    wget -i /root/dl.txt -c &&
    apt-get install -y $PACKAGES
