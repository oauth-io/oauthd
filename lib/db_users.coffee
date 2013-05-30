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

# register a new user
exports.register = check mail:check.format.mail, pass:/^.{6,}$/, (data, callback) ->
	dynsalt = Math.floor(Math.random()*9999999)
	shasum = crypto.createHash 'sha1'
	shasum.update config.staticsalt + data.pass + dynsalt
	pass = shasum.digest 'base64'

	date_inscr = (new Date).getTime()

	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		console.log data.mail, '->', err, iduser
		return callback err if err
		return callback new Error 'Mail already exists !' if iduser
		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			(db.redis.multi [
				[ 'mset', prefix+'mail', data.mail,
					prefix+'pass', pass,
					prefix+'salt', dynsalt,
					prefix+'date_inscr', date_inscr ],
				[ 'hset', 'u:mails', data.mail, val ]
			]).exec (err, res) ->
				return callback err if err
				return callback null, id:val, mail:data.mail, date_inscr:date_inscr

# get a user by his id
exports.get = check 'int', (iduser, callback) ->
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
		return callback err if err
		return callback null, id:iduser, mail:replies[0], date_inscr:(new Date replies[1])

# get a user by his mail
exports.getByMail = check check.format.mail, (mail, callback) ->
	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback err if err
		return callback new Error 'Unknow mail' unless iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
			return callback err if err
			return callback null, id:iduser, mail:replies[0], date_inscr:(new Date replies[1])

# get apps ids owned by a user
exports.getApps = check 'int', (iduser, callback) ->
	db.redis.smembers 'u:' + iduser + ':apps', callback

# check if mail & pass match
exports.login = check check.format.mail, 'string', (mail, pass, callback) ->
	db.redis.get 'u:mails', mail, (err, iduser) ->
		return callback err if err
		return callback new Error 'Unknow mail' unless iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [
			prefix+'pass',
			prefix+'salt',
			prefix+'mail',
			prefix+'date_inscr'], (err, replies) ->
				return callback err if err
				shasum = crypto.createHash 'sha1'
				shasum.update config.staticsalt + pass + replies[1]
				calcpass = shadum.digest 'base64'
				return callback new Error 'Bad password' if replies[0] != calcpass
				return callback null, id:iduser, mail:replies[2], date_inscr:(new Date replies[3])
