# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

fs = require 'fs'

config = require './config'

sdk_android_str = null

exports.get = (callback) ->
	return callback null, sdk_android_str if sdk_android_str
	fs.readFile config.rootdir + '/app/jar/oauth.jar', 'utf8', (err, data) ->
		sdk_android_str = data.replace /\{\{auth_url\}\}/g, config.host_url + config.base
		callback null, sdk_android_str