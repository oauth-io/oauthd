crypto = require 'crypto'
async = require 'async'

db = require './db'
config = require '../config'

module.exports =
	register: (data, callback) ->
		if ! data.mail || ! data.pass
			return callback new Error 'Missing parameters'
		dynsalt = Math.floor(Math.random()*9999999)
		shasum = crypto.createHash 'sha1'
		shasum.update config.staticsalt + data.pass + dynsalt
		pass = shadum.digest 'base64'

		date_inscr = (new Date).getTime()

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
				callback null, id:val, mail:data.mail, date_inscr:date_inscr

	get: (iduser, callback) ->
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
			return callback err if err
			callback null, id:iduser, mail:replies[0], date_inscr:replies[1]

	getByMail: (mail, callback) ->
		db.redis.get 'u:mails', mail, (err, iduser) ->
			return callback err if err
			return callback new Error('Unknow mail') unless iduser
			prefix = 'u:' + iduser + ':'
			db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
				return callback err if err
				callback null, id:iduser, mail:replies[0], date_inscr:replies[1]

	getApps: (iduser, callback) ->
		db.redis.smembers 'u:' + iduser + ':apps', callback

	login: (mail, pass, callback) ->
		db.redis.get 'u:mails', mail, (err, iduser) ->
			return callback err if err
			return callback new Error('Unknow mail') unless iduser
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
					if replies[0] != calcpass
						return callback new Error ('Bad password')
					callback null, id:iduser, mail:replies[2], date_inscr:replies[3]