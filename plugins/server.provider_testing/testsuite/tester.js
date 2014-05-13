var cp = require('child_process');
var express = require('express');
var fs = require('fs');
var config = require('./server/config');
var Path = require('path');
var Q = require('q');

module.exports = function(provider) {
	var defer = Q.defer();
	var app = express();
	app.get("/", function(req, res) {
		res.setHeader("Content-Type", "text/html");
		fs.readFile(Path.join(__dirname, 'server', 'index.html'), 'UTF-8', function(err, data) {
			data = data.replace(/{{oauthio_server}}/, config.oauthio_server);
			res.send(data);
		});
	});
	var consumer_server = app.listen(config.port);

	var arguments = ['test', Path.join(__dirname, 'caspertests', 'launcher.coffee'), '--provider=' + provider];

	var ps = cp.spawn('casperjs', arguments);
	var test_passed = true;
	var console_lines = [];
	ps.stdout.on('data', function(data) {
		data = data.toString().replace("\n", "");
		if (data.match(/PASS/)) {
		} else if (data.match(/FAIL/)) {
			data = data.replace(/\[[0-9;]*m/g, '');
			data = data.replace(/FAIL/, '- ');
			console_lines.push(data);
			test_passed = false;
		}
	});
	ps.stderr.on('data', function(data) {
		data = data.toString().replace("\n", "");
		if (data.match(/PASS/)) {
		} else if (data.match(/FAIL/)) {
			data = data.replace(/\[[0-9;]*m/g, '');
			data = data.replace(/FAIL/, '- ');
			console_lines.push(data);
			test_passed = false;
		}
	});

	ps.on('exit', function() {
		defer.resolve({
			passed: test_passed,
			messages: console_lines
		});
		if (process.argv.indexOf('--keepserver') === -1) consumer_server.close();
	});
	return defer.promise;
};