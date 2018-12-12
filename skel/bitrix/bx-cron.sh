#!/usr/bin/env bash

cd `dirname $0`

echo "Running bitrix cron"

php www/bitrix/modules/main/tools/cron_events.php
