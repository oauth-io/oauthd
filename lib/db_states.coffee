# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

async = require 'async'

db = require './db'
config = require './config'
check = require './check' 

# add a new token
exports.add = check key:check.format.key, provider:check.format.provider
	,token:['none','string'], expire:['none','number']
	,redirect_uri:['none','string'], (data, callback) ->

		id = db.generateUid()
		dbdata = key:data.key, provider:data.provider
		dbdata.token = data.token if data.token
		dbdata.expire = (new Date()).getTime() + data.expire if data.expire
		dbdata.redirect_uri = data.redirect_uri if data.redirect_uri
		dbdata.oauthv = data.oauthv if data.oauthv

		db.redis.hmset 'st:' + id, dbdata, (err, res) ->
			return callback err if err
			if data.expire?
				db.redis.expire 'st:' + id, data.expire
			dbdata.id = id
			callback null, dbdata

# get the token infos
exports.get = check check.format.key, (id, callback) ->
	db.redis.hgetall 'st:' + id, (err, res) ->
		return callback err if err
		res.expire = parseInt res.expire if res?.expire
		res.id = id
		callback null, res

# set the token infos
exports.set = check check.format.key, token:['none','string'], expire:['none','date']
	,redirect_uri:['none','string'], (id, data, callback) ->

		db.redis.hmset 'st:' + id, data, callback
