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
exports.add = check idapp:/^.{6,}$/, provider:check.format.provider
	,token:['none','string'], expire:['none','date']
	,redirect_uri:['none','string'], (data, callback) ->

		id = db.generateUid()
		dbdata = idapp:data.idapp, provider:data.provider
		dbdata.token = data.token if data.token?
		dbdata.expire = data.expire if data.expire?

		db.redis.hmset 'st:' + id, dbdata, (err, res) ->
			return callback err if err
			dbdata.id = id
			callback null, dbdata

# get the token infos
exports.get = check 'int', (id, callback) ->
	db.redis.hgetall 'st:' + id, callback

# set the token infos
exports.set = check 'int', token:['none','string'], expire:['none','date']
	,redirect_uri:['none','string'], (id, data, callback) ->

		db.redis.hmset 'st:' + id, data, callback
