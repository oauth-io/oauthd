# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

'use strict'

restify = require 'restify'
fs = require 'fs'
Path = require 'path'
Url = require 'url'

async = require 'async'

config = require "../config"
config.rootdir = Path.normalize __dirname + '/..'

oauthd_server = require './server'
db = require './db'

# clean exit when possible
cleanExit = (killer) ->
	k = setTimeout (->
		console.error '--- FORCING STOP'
		process.kill process.pid
	), 1500
	async.series [
		(callback) -> oauthd_server.close callback
		(callback) -> db.close callback
	], (err, res) ->
		console.log '--- successfully closed !'
		setTimeout killer, 100

# nodemon restarting
process.once 'SIGUSR2', ->
	console.log '--- closing server...'
	cleanExit -> process.kill process.pid, 'SIGUSR2'

# Fatal exception catching
process.on 'uncaughtException', (err) ->
	console.error '--- uncaughtException'
	console.error err.stack.toString()
	console.error '--- node exiting now...'
	cleanExit -> process.exit 1

# listen
oauthd_server.listen (err, server) ->
	console.log '%s listening at %s', server.name, server.url
