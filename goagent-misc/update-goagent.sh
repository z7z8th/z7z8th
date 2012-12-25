#!/bin/sh

goagent_pid=`ps aux | grep 'python.*goagent.*proxy\.py$' 2>/dev/null | grep -v 'grep' | awk '{print $2}'`
goagent_log=/tmp/goagent.log

echo "goagent_pid=$goagent_pid"
echo "goagent_log=$goagent_log"

[ -n "$goagent_pid" ] && { kill -TERM $goagent_pid; kill -KILL $goagent_pid; }

cd `dirname $0`

GA_DIR=$HOME/github/goagent
GA_DIR_LOC=$GA_DIR/local
GA_LOCAL_CERTS=$GA_DIR/../local-certs.tar.bz2

set -x

cd $GA_DIR/
tar jcvf $GA_LOCAL_CERTS local/certs/ local/CA.*
git diff local/proxy.ini >../proxy.ini.diff
git branch -a
git reset --hard HEAD
git clean -df
git pull
git apply ../proxy.ini.diff

rm -rf $GA_DIR_LOC/certs
rm $GA_DIR_LOC/CA.*
tar xvf $GA_LOCAL_CERTS
#cp ../CA.* $GA_DIR_LOC

echo "======================================"
echo "== backup->update->restore finished =="

GA_EXEC=$GA_DIR_LOC/proxy.py
GA_CONF=$GA_DIR_LOC/proxy.ini

read -p "input appid: " appid
read -p "input passwd: " passwd
sed -i -r -e "s|^(appid\\s*=).*$|\\1 $appid|" -e "s|^(password\\s*=).*$|\\1 $passwd|" $GA_CONF

echo ""
read -p "****** start goagent ?? *****" pp
echo "nohup python $GA_EXEC > $goagent_log &"
chmod 755 $GA_EXEC
nohup python $GA_EXEC > $goagent_log &

ps aux | grep 'python.*goagent.*proxy\.py$' 2>/dev/null | grep -v grep 1>/dev/null 2>&1 \
    && echo "=== succeed, start goagent" \
    || echo "*** error, start goagent"
