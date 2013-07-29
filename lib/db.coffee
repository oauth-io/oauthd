# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

crypto = require 'crypto'
redis = require 'redis'
config = require './config'
exit = require './exit'

exports.redis = redis.createClient config.redis.port, config.redis.host, config.redis.options
exports.redis.auth(config.redis.password) if config.redis.password
exports.redis.select(config.redis.database) if config.redis.database

exit.push 'Redis db', (callback) ->
	try
		exports.redis.quit() if exports.redis
	catch e
		return callback e
	callback()

exports.generateUid = (data) ->
	data ?= ''
	shasum = crypto.createHash 'sha1'
	shasum.update config.publicsalt
	shasum.update data + (new Date).getTime() + ':' + Math.floor(Math.random()*9999999)
	uid = shasum.digest 'base64'
	return uid.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '')

exports.generateHash = (data) ->
	shasum = crypto.createHash 'sha1'
	shasum.update config.staticsalt + data
	return shasum.digest 'base64'