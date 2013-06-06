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
exports.create = check name:/^.{3,}$/,domains:['none','array'], (data, callback) ->
	key = db.generateUid()
	err = new check.Error
	if data.domains
		for domain in data.domains
			err.check 'domains', domain, 'string'
	return callback err if err.failed()
	db.redis.incr 'a:i', (err, idapp) ->
		return callback err if err
		prefix = 'a:' + idapp + ':'
		cmds = [
			[ 'mset', prefix+'name', data.name,
				prefix+'key', key ],
			[ 'hset', 'a:keys', key, idapp ]
		]
		if data.domains
			# todo: in redis >= 2.4, sadd accepts multiple members
			for domain in data.domains
				cmds.push [ 'sadd', prefix + 'domains', domain ]
		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err
			callback null, id:idapp, name:data.name, key:key

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
exports.update = check check.format.key, name:['none',/^.{6,}$/], domains:['none','array'], (key, data, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		async.parallel [
			(callback) ->
				upinfos = []
				if data.name
					upinfos.push 'a:' + idapp + ':name'
					upinfos.push data.name
				return callback() if not upinfos.length
				db.redis.mset upinfos, ->
					return callback err if err
					return callback()
			(callback) ->
				return callback() if not data.domains
				exports.updateDomains key, data.domains, (err, res) ->
					return callback err if err
					return callback()
		], (err, res) ->
			return callback err if err
			return callback()

# reset app key
exports.resetKey = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		newkey = db.generateUid()
		db.redis.multi([
			['set', 'a:' + idapp + ':key', newkey]
			['hdel', 'a:keys', key]
			['hset', 'a:keys', newkey, idapp]
		]).exec (err, r) ->
			return callback err if err
			callback null, key:newkey

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

# update all authorized domains of the app
exports.updateDomains = check check.format.key, 'array', (key, domains, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp

		cmds = [['del', 'a:' + idapp + ':domains']]
		# todo: in redis >= 2.4, sadd accepts multiple members
		for domain in domains
			cmds.push [ 'sadd', 'a:' + idapp + ':domains', domain ]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err
			return callback()

# add an authorized domain to an app
exports.addDomain = check check.format.key, 'string', (key, domain, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.sadd 'a:' + idapp + ':domains', domain, (err, res) ->
			return callback err if err
			return callback new check.Error 'domain', domain + ' is already valid' if not res
			callback()

# remove an authorized domain from an app
exports.remDomain = check check.format.key, 'string', (key, domain, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.srem 'a:' + idapp + ':domains', domain, (err, res) ->
			return callback err if err
			return callback new check.Error 'domain', domain + ' is already non-valid' if not res
			callback()

# get keys infos of an app for a provider
exports.getKeyset = check check.format.key, 'string', (key, provider, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.get 'a:' + idapp + ':k:' + provider, (err, res) ->
			return callback err if err
			#return callback new check.Error 'provider', 'You have no keyset for ' + provider if not res
			return callback() if not res
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
			callback()

# get keys infos of an app for a provider
exports.remKeyset = check check.format.key, 'string', (key, provider, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.del 'a:' + idapp + ':k:' + provider, (err, res) ->
			return callback err if err
			return callback new check.Error 'provider', 'You have no keyset for ' + provider if not res
			callback()

# get keys infos of an app for all providers
exports.getKeysets = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		prefix = 'a:' + idapp + ':k:'
		db.redis.keys prefix + '*', (err, replies) ->
			return callback err if err
			callback null, (reply.substr(prefix.length) for reply in replies)
