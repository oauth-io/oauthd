# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

async = require 'async'
Mailer = require '../../lib/mailer'

{config,check,db} = shared = require '../shared'

exports.add = check /^.+/, 'int', (name, user_id, callback) ->

	prefix = "w:providers"
	count = 0;
	name = name.toLowerCase()

	db.redis.sismember [ "#{prefix}:#{name}", user_id ], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but you have already added " + name.toUpperCase() if res == 1

		db.redis.get "#{prefix}:#{name}:count", (err, res) ->

			if not res?
				count = 1
				db.redis.multi([
					[ 'sadd', "#{prefix}", name ],
					[ 'sadd', "#{prefix}:#{name}", user_id],
					[ 'mset', "#{prefix}:#{name}:name", name,
							"#{prefix}:#{name}:status", "asked",
				  			"#{prefix}:#{name}:count", count ]
				]).exec (err) ->
					return callback err if err
					return callback null, name:name, count:count
			else
				count = parseInt(res) + 1

				db.redis.multi([
					[ 'sadd', "#{prefix}:#{name}", user_id],
					[ 'mset', "#{prefix}:#{name}:count", count ]
				]).exec (err) ->
					return callback err if err
					return callback null, name:name, count:count, updated:true


exports.getList = (callback) ->

	prefix = "w:providers"

	db.redis.smembers "#{prefix}", (err, providers) ->
		return callback err if err
		return callback null, [] if not providers.length

		cmds = []
		for p in providers
			cmds.push [ "get", "#{prefix}:#{p}:name"]
			cmds.push [ "get", "#{prefix}:#{p}:status"]
			cmds.push [ "get", "#{prefix}:#{p}:count"]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of providers
				providers[i] = name:res[i * 3], status:res[i * 3 + 1], count:parseInt(res[i * 3 + 2])

			return callback null, providers


# delete a provider
exports.remove = check 'string', (provider, callback) ->
	prefix = 'w:providers:' + provider
	db.redis.sismember ['w:providers' , provider], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but the provider " + provider.toUpperCase() + " doesn't exist anymore" if res == 0

		db.redis.multi([
			[ 'del', prefix+':name', prefix+':status', prefix+':count', prefix ]
			[ 'srem', 'w:providers', provider],
		]).exec (err, replies) ->
			return callback err if err
			return callback null, name:provider


# change a status provider
exports.setStatus = check 'string', 'string', (provider, status, callback) ->
	prefix = 'w:providers:' + provider
	db.redis.sismember ['w:providers' , provider], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but the provider " + provider.toUpperCase() + " doesn't exist" if res == 0

		db.redis.set prefix+':status', status, (err, reply) ->
			return callback err if err
			return callback null, name:provider, status:status
