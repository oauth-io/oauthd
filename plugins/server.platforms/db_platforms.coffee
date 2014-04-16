# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

async = require 'async'
{config,check,db} = shared = require '../shared'

exports.get = check 'int', (idplatform, callback) ->
	return callback new check.Error 'Unknown platform id' unless idplatform
	prefix = 'p:' + idplatform + ':'	
	db.redis.mget [ prefix + 'name',
		prefix + 'date_creation' ]
	, (err, replies) ->
		return callback err if err
		platform =
			id:idplatform,
			name:replies[0],
			date_creation:replies[1]
		for field of platform
			platform[field] = '' if platform[field] == 'undefined'
		return callback null, platform
			
exports.getAll = (callback) ->
	db.redis.hgetall 'p:platforms_name', (err, platforms) =>
		return callback err if err
		cmds = []
		for name,idplatform of platforms
			cmds.push ['get', 'p:' + idplatform + ':date_creation']
		db.redis.multi(cmds).exec (err, r) =>
			return next err if err
			i = 0
			for name,idplatform of platforms
				platforms[name] = id:idplatform, name:name, date_creation:r[i]
				i++
			callback null, platforms

exports.add = (platform_name, callback) ->
	return callback true if not platform_name?
	db.redis.incr 'p:i', (err, val) ->
		return callback err if err
		prefix = 'p:' + val + ':'
		date_now = (new Date).getTime()
		arr = ['mset', prefix+'name', platform_name,
				prefix+'date_creation', date_now ]
		db.redis.multi([
				arr,
				[ 'hset', 'p:platforms_name', platform_name, val ]
			]).exec (err, res) ->
				return callback err if err
				platform = id:val, name:platform_name, date_creation:date_now
				return callback null, platform

exports.removeAdminsOfPlatform = (platform_name, callback) ->
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

exports.remove = check 'int', (idplatform, callback) ->
	return callback new check.Error 'Unknown platform id' unless idplatform
	prefix = 'p:' + idplatform + ':'
	db.redis.get prefix+'name', (err, name) ->
		return callback err if err
		return callback new check.Error 'Unknown platform' unless name
		db.redis.multi([
			[ 'hdel', 'p:platforms_name', name ]
			[ 'del', prefix+'name', prefix+'date_creation' ]
		]).exec (err, replies) ->
			return callback err if err
			platform = id:idplatform, name:name
			shared.emit 'platform.remove', platform
			return callback null, replies

exports.addAdmin = (idplatform, iduser, callback) ->
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

exports.getAdmins = (callback) ->
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
		
exports.removeAdmin = check 'int', (iduser, callback) ->
	return callback new check.Error 'Unknown user id' unless iduser
	db.redis.multi([
		['del', "u:" + iduser + ":platform_admin" ]
		[ 'hdel', 'u:platforms_admin', iduser ]
	]).exec (err, res) -> 
		return callback err if err
		return callback null, res



