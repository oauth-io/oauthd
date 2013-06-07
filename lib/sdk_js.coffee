# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

fs = require 'fs'

config = require './config'

sdk_js_str = null

exports.get = (callback) ->
	return callback null, sdk_js_str if sdk_js_str
	fs.readFile config.rootdir + '/app/js/oauth.js', 'utf8', (err, data) ->
		sdk_js_str = data.replace /\{\{auth_url\}\}/g, config.host_url + config.base
		callback null, sdk_js_str
