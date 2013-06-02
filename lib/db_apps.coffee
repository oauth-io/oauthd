# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

async = require 'async'

db = require './db'
config = require './config'
check = require './check'

# create a new app
exports.create = check name:/^.{6,}$/, (data, callback) ->
	key = db.generateUid()

	db.redis.incr 'a:i', (err, val) ->
		return callback err if err
		prefix = 'a:' + val + ':'
		db.redis.multi([
			[ 'mset', prefix+'name', data.name,
				prefix+'key', key ],
			[ 'hset', 'a:keys', key, val ]
		]).exec (err, res) ->
			return callback err if err
			callback null, id:val, name:data.name, key:key

# get the app infos by its id
exports.getById = check 'int', (idapp, callback) ->
	prefix = 'a:' + idapp + ':'
	db.redis.mget [prefix+'name', prefix+'key'], (err, replies) ->
		return callback err if err
		callback null, id:idapp, name:replies[0], key:replies[1]

# get the app infos
exports.get = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		prefix = 'a:' + idapp + ':'
		db.redis.mget [prefix+'name', prefix+'key'], (err, replies) ->
			return callback err if err
			callback null, id:idapp, name:replies[0], key:replies[1]

# update app infos
exports.update = check check.format.key, name:['none',/^.{6,}$/], (key, data, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		upinfos = {}
		upinfos['a:' + idapp + ':name'] = data.name if data.name
		return callback() if not upinfos.length
		db.redis.mset upinfos, callback

# reset app key
exports.resetKey = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		newkey = generateKey()
		db.redis.multi([
			['set', 'a:' + idapp + ':key', key]
			['hdel', 'a:keys', key]
			['hset', 'a:keys', newkey, idapp]
		]).exec (err, r) ->
			return callback err if err
			callback key:newkey

# remove an app
exports.remove = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.multi([
			['hdel', 'a:keys', key],
			['keys', 'a:' + idapp + ':*']
		]).exec (err, replies) ->
			return callback err if err
			db.redis.del replies[1], (err, removed) ->
				return callback err if err
				return callback()

# get authorized domains of the app
exports.getDomains = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.smembers 'a:' + idapp + ':domains', callback

# add an authorized domain to an app
exports.addDomain = check check.format.key, 'string', (key, domain, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.sadd 'a:' + idapp + ':domains', domain, callback

# remove an authorized domain from an app
exports.remDomain = check check.format.key, 'string', (key, domain, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.srem 'a:' + idapp + ':domains', domain, callback

# get keys infos of an app for a provider
exports.getKeyset = check check.format.key, 'string', (key, provider, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.get 'a:' + idapp + ':k:' + provider, (err, res) ->
			return callback err if err
			try
				res = JSON.parse(res)
			catch e
				return callback err if err
			callback null, res

# get keys infos of an app for a provider
exports.addKeyset = check check.format.key, 'string', 'object', (key, provider, data, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.set 'a:' + idapp + ':k:' + provider, JSON.stringify(data), (err, res) ->
			return callback err if err
			callback null, res

# get keys infos of an app for a provider
exports.remKeyset = check check.format.key, 'string', (key, provider, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.del 'a:' + idapp + ':k:' + provider, (err, res) ->
			return callback err if err
			callback null, res

# get keys infos of an app for all providers
exports.getKeysets = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		prefix = 'a:' + idapp + ':k:'
		db.redis.keys prefix + '*', (err, replies) ->
			return callback err if err
			callback null, (reply.substr(prefix.length) for reply in replies)
