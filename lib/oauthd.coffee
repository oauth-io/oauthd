# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

Path = require 'path'
config = require "./config"
config.rootdir = Path.normalize __dirname + '/..'

# initialize plugins
plugins = require "./plugins"
plugins.init()

# start server
server = require './server'
server.listen (err, srv) ->
	if err
		console.error 'Error while initialisation', err.stack.toString()
	else
		console.log '%s listening at %s', srv.name, srv.url
