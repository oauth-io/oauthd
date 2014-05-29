var cp = require('child_process');
var express = require('express');

var fs = require('fs');
var config = require('./server/config');

console.log("Creating test consumer server for sdk");
var app = express();

app.get("/", function(req, res) {
    res.setHeader("Content-Type", "text/html");

    fs.readFile('./server/index.html', 'UTF-8', function(err, data) {
    	data = data.replace(/{{oauthio_server}}/, config.oauthio_server);
        res.send(data);
    });
});

var consumer_server = app.listen(config.port);
console.log ("Now starting functional tests");

var arguments = ['test', './caspertests/launcher.coffee'];

if (process.argv)
	for (var k in process.argv) {
		if (k > 1)
		arguments.push(process.argv[k]);
	}

console.log(arguments);

var ps = cp.spawn('casperjs', arguments);

ps.stdout.on('data', function (data) {
	console.log(data.toString().replace("\n", ""));
});

ps.stderr.on('data', function (data) {
	console.log(data.toString().replace("\n", ""));
});

ps.on('exit', function () {
	consumer_server.close();
});