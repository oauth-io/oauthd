var cp = require('child_process');
var express = require('express');
var fs = require('fs');
var config = require('./server/config');
var Path = require('path');
var Q = require('q');



module.exports = function(provider) {
	var defer = Q.defer();
	console.log("Creating test consumer server for sdk");
	var app = express();
	app.get("/", function(req, res) {
		res.setHeader("Content-Type", "text/html");
		fs.readFile(Path.join(__dirname, 'server', 'index.html'), 'UTF-8', function(err, data) {
			data = data.replace(/{{oauthio_server}}/, config.oauthio_server);
			res.send(data);
		});
	});
	var consumer_server = app.listen(config.port);
	console.log("Now starting functional tests");
	var arguments = ['test', Path.join(__dirname, 'caspertests', 'launcher.coffee'), '--provider=' + provider];

	var ps = cp.spawn('casperjs', arguments);
	ps.stdout.on('data', function(data) {
		data = data.toString().replace("\n", "");
		if (data.match(/PASS/)) {
			console.log('something passed');
		} else if (data.match(/FAIL/)) {
			console.log('something failed');
		}
	});
	ps.stderr.on('data', function(data) {
		data = data.toString().replace("\n", "");
		if (data.match(/PASS/)) {
			console.log('something passed');
		} else if (data.match(/FAIL/)) {
			console.log('something failed');
		}
	});

	ps.on('exit', function() {
		console.log('finished tests on provider');
		if (process.argv.indexOf('--keepserver') === -1) consumer_server.close();
		defer.resolve();
	});
	return defer.promise;
};