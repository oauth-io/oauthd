#! /bin/bash

oauthdurl=`node -e 'var c=require("./lib/config");console.log("http://127.0.0.1:"+c.port+c.base)'`

if curl -o /dev/null --silent --fail "$oauthdurl"; then
	echo -n "Stopping OAuth daemon..."
	forever stop lib/oauthd.js >/dev/null 2>/dev/null
	echo " OK"
else
	echo "OAuth daemon is not running"
fi
