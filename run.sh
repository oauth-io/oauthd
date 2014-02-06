#! /bin/bash

oauthdurl=`node -e 'var c=require("./lib/config");console.log("http://127.0.0.1:"+c.port+c.base)'`

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
	exit
else
	echo -n "."
fi
done
echo " Failed"