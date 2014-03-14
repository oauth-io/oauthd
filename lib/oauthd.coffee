# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

startTime = new Date

Path = require 'path'
config = require "./config"
async = require "async"
config.rootdir = Path.normalize __dirname + '/..'

# request FIX
qs = require 'request/node_modules/qs'
oldstringify = qs.stringify
qs.stringify = ->
	result = oldstringify.apply(qs, arguments)
	result = result.replace /!/g, '%21'
	result = result.replace /'/g, '%27'
	result = result.replace /\(/g, '%28'
	result = result.replace /\)/g, '%29'
	result = result.replace /\*/g, '%2A'
	return result
# --

# initialize plugins
exports.plugins = plugins = require "./plugins"
plugins.init()

# start server
exports.server = server = require './server'
async.series [
	plugins.data.db.providers.getList,
	server.listen
], (err) ->
	if err
		console.error 'Error while initialisation', err.stack.toString()
		plugins.data.emit 'server', err
	else
		console.log 'Server is ready (load time: ' + Math.round(((new Date) - startTime) / 10) / 100 + 's)', (new Date).toGMTString()