# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

async = require 'async'

{config,check,db} = shared = require '../shared'

# register a new user
exports.register = check mail:check.format.mail, (data, callback) ->
	dynsalt = Math.floor(Math.random()*9999999)
	# pass = db.generateHash data.pass + dynsalt
	date_inscr = (new Date).getTime()
	key = db.generateHash dynsalt
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'This email already exists !' if iduser
		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			db.redis.multi([
				[ 'mset', prefix+'mail', data.mail,
					# prefix+'pass', pass,
					# prefix+'salt', dynsalt,
					prefix+'key', key,
					prefix+'validated', 0,
					prefix+'date_inscr', date_inscr ],
				[ 'hset', 'u:mails', data.mail, val ]
			]).exec (err, res) ->
				return callback err if err
				return callback null, id:val, mail:data.mail, date_inscr:date_inscr


exports.isValidable = check mail:check.format.mail, (data, callback) ->
	key = data.key
	mail = data.mail
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback null, is_validable: false if not iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'key', prefix+'validated'], (err, replies) ->
			return callback err if err
			return callback null, is_validable: false if replies[2] || replies[1] != key
			return callback null, is_validable: true

# validate user mail
exports.userValidate = check mail:check.format.mail, pass:/^.{6,}$/, (data, callback) ->
	dynsalt = Math.floor(Math.random()*9999999)
	pass = db.generateHash data.pass + dynsalt
	key = db.generateHash dynsalt
	@isValidable {
		mail: data.mail,
		key: data.key
	}, (err, data) ->
		return callback new check.Error "This page does not exists." if data.is_validable || err
		db.redis.mset [
			prefix+'validated', 1,
			prefix+'pass', pass,
			prefix+'key', key
		]
		return callback null, id:iduser

# lost password
exports.lostPassword = check mail:check.format.mail, (data, callback) ->
	mail = data.mail
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback check.Error "This email isn't registered" if not iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'key', prefix+'validated'], (err, replies) ->
			return callback check.Error "This email is not validated yet. Patience... :)" if replies[2] == 0
			#send mail with key

# change password
exports.changePassword = check mail:check.format.mail, (data, callback) ->


# get a user by his id
exports.get = check 'int', (iduser, callback) ->
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' if not replies[1]
		return callback null, id:iduser, mail:replies[0], date_inscr:replies[1]

# delete a user account
exports.remove = check 'int', (iduser, callback) ->
	prefix = 'u:' + iduser + ':'
	db.redis.get prefix+'mail', (err, mail) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' unless mail
		db.redis.multi([
			[ 'hdel', 'u:mails', mail ]
			[ 'del', prefix+'mail', prefix+'pass', prefix+'salt'
					, prefix+'apps', prefix+'date_inscr' ]
		]).exec (err, replies) ->
			return callback err if err
			callback()

# get a user by his mail
exports.getByMail = check check.format.mail, (mail, callback) ->
	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' unless iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
			return callback err if err
			return callback null, id:iduser, mail:replies[0], date_inscr:replies[1]

# get apps ids owned by a user
exports.getApps = check 'int', (iduser, callback) ->
	db.redis.smembers 'u:' + iduser + ':apps', (err, apps) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' if not apps
		return callback null, [] if not apps.length
		keys = ('a:' + app + ':key' for app in apps)
		db.redis.mget keys, (err, appkeys) ->
			return callback err if err
			return callback null, appkeys

# is an app owned by a user
exports.hasApp = check 'int', check.format.key, (iduser, key, callback) ->
	db.apps.get key, (err, app) ->
		return callback err if err
		db.redis.sismember 'u:' + iduser + ':apps', app.id, callback

# check if mail & pass match
exports.login = check check.format.mail, 'string', (mail, pass, callback) ->
	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' unless iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [
			prefix+'pass',
			prefix+'salt',
			prefix+'mail',
			prefix+'date_inscr'], (err, replies) ->
				return callback err if err
				calcpass = db.generateHash pass + replies[1]
				return callback new check.Error 'Bad password' if replies[0] != calcpass
				return callback null, id:iduser, mail:replies[2], date_inscr:replies[3]

## Event: add app to user when created
shared.on 'app.create', (req, app) ->
	if req.user?.id
		db.redis.sadd 'u:' + req.user.id + ':apps', app.id

## Event: remove app from user when deleted
shared.on 'app.remove', (req, app) ->
	if req.user?.id
		db.redis.srem 'u:' + req.user.id + ':apps', app.id

db.users = exports