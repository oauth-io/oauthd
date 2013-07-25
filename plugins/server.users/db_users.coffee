# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

async = require 'async'
Mailer = require '../../lib/mailer'

{config,check,db} = shared = require '../shared'

# register a new user
exports.register = check mail:check.format.mail, (data, callback) ->
	date_inscr = (new Date).getTime()
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'This email already exists !' if iduser
		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			db.redis.multi([
				[ 'mset', prefix+'mail', data.mail,
					prefix+'key', db.generateUid(),
					prefix+'validated', 0,
					prefix+'date_inscr', date_inscr ],
				[ 'hset', 'u:mails', data.mail, val ]
			]).exec (err, res) ->
				return callback err if err
				user = id:val, mail:data.mail, date_inscr:date_inscr
				shared.emit 'user.register', user
				return callback null, user

# update user infos
exports.updateAccount = (req, callback) ->

	data = req.body	
	user_id = req.user.id	
	prefix = "u:#{user_id}:"
	old_email = null

	db.redis.mget [ prefix + 'mail'], (err, res) =>
		old_email = res[0]
			
	db.redis.hget 'u:mails', data.email, (err, id) ->
		
		is_new_email = (old_email != data.email)
		validation_key = db.generateUid()		
		
		if is_new_email
			return callback err if err
			return callback new check.Error "#{data.email} already exists" if id

			db.redis.multi([

				[ 'hdel', 'u:mails', old_email ],
				[ 'hset', 'u:mails', data.email, user_id ],

				[ 'mset', prefix + 'mail', data.email,
					prefix + 'name', data.name,
					prefix + 'location', data.location,
					prefix + 'company', data.company,
					prefix + 'website', data.website,
					prefix + 'validated', 0,
					prefix + 'key', validation_key]		

			]).exec (err, res) ->						
				return callback err if err

				#send mail with key
				options =
						to:
							email: data.email
						from:
							name: 'OAuth.io'
							email: 'team@oauth.io'
						subject: 'OAuth.io - You email address has been updated'
						body: "Hello,\n\n
In order to validate your new email address, please click the following link: https://" + config.url.host + "/#/validate/" + user_id + "/" + validation_key + ".\n

--\n
OAuth.io Team"
				mailer = new Mailer options
				mailer.send (err, result) ->
					return callback err if err						
					user = id:user_id, mail:data.email, name:data.name, company:data.company, website:data.website, location:data.location
					return callback null, user						
		else	
			db.redis.mset [	
				prefix + 'mail', data.email,
				prefix + 'name', data.name,
				prefix + 'location', data.location,
				prefix + 'company', data.company,
				prefix + 'website', data.website
			], (err) ->
				return callback err if err
				user = id:user_id, mail:data.email, name:data.name, company:data.company, website:data.website, location:data.location
				return callback null, user


exports.isValidable = (data, callback) ->
	key = data.key
	iduser = data.id
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix+'mail', prefix+'key', prefix+'validated', prefix+'pass'], (err, replies) ->
		return callback err if err

		if replies[3]? # pass ok, validate new email address		
			db.redis.mset [prefix+'validated', 1], (err) ->				
				return callback err if err
				return callback null, is_updated: true, mail: replies[0], id: iduser
		else
			if replies[2] == '1' || replies[1] != key
				return callback null, is_validable: false
			return callback null, is_validable: true, mail: replies[0], id: iduser

# validate user mail
exports.validate = check pass:/^.{6,}$/, (data, callback) ->
	dynsalt = Math.floor(Math.random()*9999999)
	pass = db.generateHash data.pass + dynsalt
	exports.isValidable {
		id: data.id,
		key: data.key
	}, (err, res) ->
		return callback new check.Error "This page does not exists." if not res.is_validable or err
		prefix = 'u:' + res.id + ':'
		db.redis.mset [
			prefix+'validated', 1,
			prefix+'pass', pass,
			prefix+'salt', dynsalt,
			prefix+'key', db.generateUid()
		], (err) ->
			return err if err
			return callback null, mail: res.mail, id: res.id

# lost password
exports.lostPassword = check mail:check.format.mail, (data, callback) ->

	mail = data.mail
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error "This email isn't registered" if not iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'key', prefix+'validated'], (err, replies) ->
			return callback new check.Error "This email is not validated yet. Patience... :)" if replies[2] == '0'
			# ok email validated  (contain password)
			key = replies[1]
			if key.length == 0
				dynsalt = Math.floor(Math.random() * 9999999)
				key = db.generateHash(dynsalt).replace(/\=/g, '').replace(/\+/g, '').replace(/\//g, '')

				# set new key
				db.redis.mset [
					prefix + 'key', key
				], (err, res) ->
					return err if err

			#send mail with key
			options =
					to:
						email: replies[0]
					from:
						name: 'OAuth.io'
						email: 'team@oauth.io'
					subject: 'OAuth.io - Lost Password'
					body: "Hello,\n\n
Did you forget your password ?\n
To change it, please use the follow link to reset your password.\n\n

https://oauth.io/#/resetpassword/#{iduser}/#{key}\n\n

--\n
OAuth.io Team"
				mailer = new Mailer options
				mailer.send (error, result) ->
					return callback error if error
					return callback null

exports.isValidKey = (data, callback) ->
	key = data.key
	iduser = data.id
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix + 'mail', prefix + 'key'], (err, replies) ->
		return callback err if err

		if replies[1].replace(/\=/g, '').replace(/\+/g, '') != key
			return callback null, isValidKey: false

		return callback null, isValidKey: true, email: replies[0], id: iduser



exports.resetPassword = check pass:/^.{6,}$/, (data, callback) ->

	exports.isValidKey {
		id: data.id,
		key: data.key
	}, (err, res) ->
		return callback err if err
		return callback new check.Error "This page does not exists." if not res.isValidKey

		prefix = 'u:' + res.id + ':'
		dynsalt = Math.floor(Math.random() * 9999999)
		pass = db.generateHash data.pass + dynsalt

		db.redis.mset [
			prefix + 'pass', pass,
			prefix + 'salt', dynsalt,
			prefix + 'key', '' # clear
		], (err) ->
			return callback err if err
			return callback null, email:res.email, id:res.id

# change password
exports.changePassword = check mail:check.format.mail, (data, callback) ->
	return callback new check.Error "Not implemented yet"


# get a user by his id
exports.get = check 'int', (iduser, callback) ->
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix+'mail', prefix+'date_inscr', prefix + 'name', prefix + 'location', prefix + 'company', prefix + 'website'], (err, replies) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' if not replies[1]
		return callback null, id:iduser, mail:replies[0], date_inscr:replies[1], name: replies[2], location: replies[3], company: replies[4], website: replies[5]

# delete a user account
exports.remove = check 'int', (iduser, callback) ->
	prefix = 'u:' + iduser + ':'
	db.redis.get prefix+'mail', (err, mail) ->
		return callback err if err
		return callback new check.Error 'Unknown user' unless mail
		exports.getApps iduser, (err, appkeys) ->
			tasks = []
			for key in appkeys
				do (key) ->
					tasks.push (cb) -> db.apps.remove key, cb
			async.series tasks, (err) ->
				return callback err if err

				db.redis.multi([
					[ 'hdel', 'u:mails', mail ]
					[ 'del', prefix+'mail', prefix+'pass', prefix+'salt', prefix+'validated', prefix+'key'
							, prefix+'apps', prefix+'date_inscr' ]
				]).exec (err, replies) ->
					return callback err if err
					shared.emit 'user.remove', mail:mail
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
			prefix+'date_inscr',
			prefix+'validated'], (err, replies) ->
				return callback err if err
				calcpass = db.generateHash pass + replies[1]
				return callback new check.Error 'Bad password' if replies[0] != calcpass || replies[4] != "1"
				return callback null, id:iduser, mail:replies[2], date_inscr:replies[3]

## Event: add app to user when created
shared.on 'app.create', (req, app) ->
	if req.user?.id
		db.redis.sadd 'u:' + req.user.id + ':apps', app.id

## Event: remove app from user when deleted
shared.on 'app.remove', (req, app) ->
	if req.user?.id
		db.redis.srem 'u:' + req.user.id + ':apps', app.id
