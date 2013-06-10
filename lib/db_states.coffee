# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

async = require 'async'

db = require './db'
config = require './config'
check = require './check' 

# add a new state
exports.add = check key:check.format.key, provider:check.format.provider
	, token:['none','string'], expire:['none','number'], oauthv:'string'
	, origin:['none','string'], redirect_uri:['none','string']
	, (data, callback) ->

		id = db.generateUid()
		dbdata = key:data.key, provider:data.provider
		dbdata.token = data.token if data.token
		dbdata.expire = (new Date()).getTime() + data.expire if data.expire
		dbdata.redirect_uri = data.redirect_uri if data.redirect_uri
		dbdata.oauthv = data.oauthv if data.oauthv
		dbdata.origin = data.origin if data.origin

		db.redis.hmset 'st:' + id, dbdata, (err, res) ->
			return callback err if err
			if data.expire?
				db.redis.expire 'st:' + id, data.expire
			dbdata.id = id
			callback null, dbdata

# get the state infos
exports.get = check check.format.key, (id, callback) ->
	db.redis.hgetall 'st:' + id, (err, res) ->
		return callback err if err
		return callback() if not res
		res.expire = parseInt res.expire if res?.expire
		res.id = id
		callback null, res

# set the state infos
exports.set = check check.format.key
	, token:['none','string'], expire:['none','number']
	, origin:['none','string'], redirect_uri:['none','string']
	, (id, data, callback) ->

		db.redis.hmset 'st:' + id, data, callback

# set the state's token
exports.setToken = check check.format.key, 'string', (id, token, callback) ->
	db.redis.hset 'st:' + id, 'token', token, callback