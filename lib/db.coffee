# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

redis = require 'redis'
exit = require './exit'

exports.redis = redis.createClient()

exit.push 'Redis db', (callback) ->
	try
		exports.redis.quit() if exports.redis
	catch e
		return callback e
	callback()