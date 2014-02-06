#! /bin/bash

myreadlink() { [ ! -h "$1" ] && echo "$1" || (local link="$(expr "$(command ls -ld -- "$1")" : '.*-> \(.*\)$')"; cd $(dirname $1); myreadlink "$link" | sed "s|^\([^/].*\)\$|$(dirname $1)/\1|"); }
whereis_realpath() { local SCRIPT_PATH=$1; myreadlink ${SCRIPT_PATH} | sed "s|^\([^/].*\)\$|$(dirname ${SCRIPT_PATH})/\1|"; }
cd $(dirname $(whereis_realpath ${0}))

oauthdurl=`node -e 'var c=require("./lib/config");console.log("http://127.0.0.1:"+c.port+c.base)'`

case "$1" in
start)
	if curl -o /dev/null --silent --fail "$oauthdurl"; then
		echo -n "Stopping OAuth daemon..."
		forever stop lib/oauthd.js >/dev/null 2>/dev/null
		echo " OK"
	fi
	echo -n "Starting OAuth daemon."
	forever --minUptime 1000 --spinSleepTime 1000 -a -l forever.log -o out.log -e err.log start lib/oauthd.js >/dev/null 2>/dev/null
	for i in {1..10}
	do
		sleep 1
	if curl -o /dev/null --silent --fail "$oauthdurl"; then
		echo " OK"
		node -e 'var c=require("./lib/config");console.log("Admin interface at "+c.host_url+c.base+"/admin")'
		exit 0
	else
		echo -n "."
	fi
	done
	echo " Failed"
;;
status)
	if curl -o /dev/null --silent --fail "$oauthdurl"; then
		echo "OAuth daemon is running"
	else
		echo "OAuth daemon is stopped"
	fi
;;
stop)
	if curl -o /dev/null --silent --fail "$oauthdurl"; then
		echo -n "Stopping OAuth daemon..."
		forever stop lib/oauthd.js >/dev/null 2>/dev/null
		echo " OK"
	else
		echo "OAuth daemon is already stopped"
	fi
;;
restart)
	$0 stop
	$0 start
;;
startsync)
	forever --minUptime 1000 --spinSleepTime 1000 -a -l forever.log -o out.log -e err.log lib/oauthd.js
;;
config)
	if [ ! -f ./config.local.js ]; then
		cp ./config.js ./config.local.js
	fi
	if [ "$EDITOR" != "" ]; then
		$EDITOR config.local.js
	else
		echo "You can use 'EDITOR=xxx oauthd config' to set the editor to use. Defaulting to vi..."
		vi config.local.js
	fi
;;
*)
	echo "Usage: oauthd {status|config|start|stop|restart}"
	exit 1
esac