# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

async = require 'async'
{config,check,db} = shared = require '../shared'

exports.add = (idplatform, iduser, callback) ->
	return callback new check.Error 'Unknown platform id' unless idplatform
	return callback new check.Error 'Unknown user id' unless iduser
	db.users.get iduser, (err, user) ->
		return callback err if err or not user?
		db.platforms.get idplatform, (err, platform) ->
			return callback err if err
			return callback new check.Error 'Unknown platform' unless platform
			db.redis.multi([
				['set', "u:" + iduser + ":platform_admin", platform.name ]
				[ 'hset', 'u:platforms_admin', iduser, platform.name ]
			]).exec (err, res) ->
				return callback err if err 
				return callback null, res

exports.getAll = (callback) ->
	db.redis.hgetall 'u:platforms_admin', (err, users) =>
		return next err if err
		admins = []
		tasks = []
		for iduser, platform_name of users
			do (iduser) ->
				tasks.push (cb) -> 
					db.users.get iduser, (err, user) -> 
						return cb err if err
						admins.push user.profile
						cb()
		async.series tasks, (err) ->
			return callback err if err
			return callback null, admins
		
exports.remove = check 'int', (iduser, callback) ->
	return callback new check.Error 'Unknown user id' unless iduser
	db.redis.multi([
		['del', "u:" + iduser + ":platform_admin" ]
		[ 'hdel', 'u:platforms_admin', iduser ]
	]).exec (err, res) -> 
		return callback err if err
		return callback null, res


exports.removeAllFrom = (platform_name, callback) ->
	db.redis.hgetall 'u:platforms_admin', (err, users) =>
		return next err if err
		tasks = []
		for iduser, p_name of users
			if p_name is platform_name
				do (iduser) ->
					tasks.push (cb) -> 
						db.redis.multi([
							['del', "u:" + iduser + ":platform_admin" ]
							[ 'hdel', 'u:platforms_admin', iduser ]
						]).exec (err, res) -> 
							return callback err if err
							cb()
		async.series tasks, (err) ->
			return callback err if err
			return callback null

