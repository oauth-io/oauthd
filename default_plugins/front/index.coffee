
express = require 'express'
fs = require 'fs'

exports.setup = (callback) ->
	@server.get /^(\/.*)/, (req, res, next) ->
		fs.stat __dirname + '/public' + req.params[0], (err, stat) ->
			if stat?.isFile()
				next()
				return
			else
				fs.readFile __dirname + '/public/index.html', {encoding: 'UTF-8'}, (err, data) ->
					res.setHeader 'Content-Type', 'text/html'
					res.send 200, data
					return
	, express.static(__dirname + '/public')
	callback()