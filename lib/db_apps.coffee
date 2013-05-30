# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

crypto = require 'crypto'
async = require 'async'

db = require './db'
config = require '../config'
check = require './check'

# create a new app
exports.create = check name:/^.{6,}$/, (data, callback) ->
	shasum = crypto.createHash 'sha1'
	shasum.update config.publicsalt
	shasum.update (new Date).getTime()
	shasum.update Math.floor(Math.random()*9999999)
	key = shasum.digest 'base64'
	key = key.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '')

	db.redis.incr 'a:i', (err, val) ->
		return callback err if err
		prefix = 'a:' + val + ':'
		(db.redis.multi [
			[ 'mset', prefix+'name', data.name,
				prefix+'key', key ],
			[ 'hset', 'a:keys', key, val ]
		]).exec (err, res) ->
			return callback err if err
			callback null, id:val, name:data.name, key:key

# get the app infos
exports.get = check 'int', (idapp, callback) ->
	prefix = 'a:' + idapp + ':'
	db.redis.mget [prefix+'name', prefix+'key'], (err, replies) ->
		return callback err if err
		callback null, id:idapp, name:replies[0], key:replies[1]

# get the app infos by its key
exports.getByKey = check 'int', (key, callback) ->
	db.redis.get 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new Error('Unknown key') unless idapp
		prefix = 'a:' + idapp + ':'
		db.redis.mget [prefix+'name', prefix+'key'], (err, replies) ->
			return callback err if err
			callback null, id:idapp, name:replies[0], key:replies[1]

# get authorized domains of the app
exports.getDomains = check 'int', (idapp, callback) ->
	db.redis.smembers 'a:' + idapp + ':domains', callback

# add an authorized domain to an app
exports.addDomain = check 'int', 'string', (idapp, domain, callback) ->
	db.redis.sadd 'a:' + idapp + ':domains', domain, callback

# remove an authorized domain from an app
exports.remDomain = check 'int', 'string', (idapp, domain, callback) ->
	db.redis.srem 'a:' + idapp + ':domains', domain, callback

# get keys infos of an app for a provider
exports.getKeyset = check 'int', 'string', (idapp, provider, callback) ->
	db.redis.get 'a:' + idapp + ':k:' + provider, (err, res) ->
		return callback err if err
		try
			res = JSON.parse(res)
		catch e
			return callback err if err
		callback null, res

# get keys infos of an app for all providers
exports.getKeysets = check 'int', (idapp, callback) ->
	prefix = 'a:' + idapp + ':k:'
	db.redis.keys prefix + '*', (err, replies) ->
		return callback err if err
		callback null, (reply.substr(prefix.length) for reply in replies)
