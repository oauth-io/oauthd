# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

async = require 'async'
config = require './config'

shared = require '../plugins/shared'
shared.exit = require './exit'
shared.check = require './check'
shared.db = require './db'
shared.db.apps = require './db_apps'
shared.db.providers = require './db_providers'
shared.db.states = require './db_states'
shared.config = config
shared.plugins = exports

exports.plugin = {}
exports.data = shared

exports.load = (plugin_name) ->
	plugin = require '../plugins/' + plugin_name + '/' + plugin_name.replace(/\./g,'_')
	exports.plugin[plugin_name] = plugin

exports.init = ->
	for plugin in config.plugins
		exports.load plugin

exports.run = (name, args, callback) ->
	if typeof args == 'function'
		callback = args
		args = []
	args.push null
	calls = []
	for k,plugin of exports.plugin
		if plugin[name]
			do (plugin) ->
				calls.push (cb) -> args[args.length-1] = cb; plugin[name].apply shared, args
	async.series calls, ->
		args.pop()
		callback.apply @,arguments

exports.runSync = (name, args) ->
	for k,plugin of exports.plugin
		if plugin[name]
			plugin[name].apply shared, args