restify = require 'restify'
ecstatic = require 'ecstatic'
fs = require 'fs'

exports.setup = (callback) ->
	@server.get /^(\/.*)/, (req, res, next) ->
		fs.stat __dirname + '/public' + req.params[0], (err, stat) ->
			if stat?.isFile()
				next()
				return
			else
				console.log 'index service'
				fs.readFile __dirname + '/public/index.html', {encoding: 'UTF-8'}, (err, data) ->
					res.setHeader 'Content-Type', 'text/html'
					res.send 200, data
					return
	, restify.serveStatic
		directory: __dirname + '/public'
		default: __dirname + '/public/index.html'
	callback()