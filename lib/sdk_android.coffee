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
	fileStream = fs.createReadStream(config.rootdir + '/app/jar/oauth.jar')
	fileStream.pipe(res);
	res.once 'end', -> next false