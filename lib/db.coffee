# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

redis = require 'redis'

db = close: (callback) ->
	try
		db.redis.quit() if db.redis
	catch e
		return callback e
	callback()

try
	db.redis = redis.createClient()
catch e
	return setup e

module.exports = db