# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

fs = require "fs"
Path = require "path"

config = require "./config"
check = require "./check"

providers =
	_list:{},
	list: ->
		now = (new Date).getTime()
		if now > expire
			fs.readdir config.rootdir + '/providers', (err, files) ->
				return if err
				_list = (file.substr(0, file.length - 5) for file in files)
			expire = now + 15
	expire: 0
providers.list()

# get a provider's description
exports.get = (provider, callback) ->
	provider_name = provider
	providers_dir = config.rootdir + '/providers'
	provider = Path.resolve providers_dir, provider + '.json'
	if Path.relative(providers_dir, provider).substr(0,2) == ".."
		return callback new check.Error 'Not authorized'

	fs.readFile provider, (err, data) ->
		return callback err if err
		content = null
		try
			content = JSON.parse data
		catch err
			return callback err
		content.provider = provider_name
		callback null, content

# get providers list
exports.getList = (callback) ->
	callback null, providers.list()