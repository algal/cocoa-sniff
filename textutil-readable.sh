#!/bin/sh
ENCODING=$1
FILENAME=$2
textutil -cat txt -stdout -encoding utf-8 -format txt -inputencoding $1 $2 > /dev/null 2>&1
RETCODE=$?
echo $RETCODE
if [ $RETCODE -eq 0 ]; then
    echo "YES"
else
    echo "NO"
fi
    
