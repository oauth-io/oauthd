# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

restify = require 'restify'
{config,check,db} = shared = require '../shared'

# data.name - Required - string
# The name of the user.
# data.mail - Required - string
# The mail of the user.
# data.pass - Required - string
# The password of the user.
# data.platform - Required - string
# The name of your platform.
exports.create = (data, admin, callback) ->
	console.log "db_platforms_users create data", data
	console.log "db_platforms_users create admin", admin
	if not data?
		return callback new restify.MissingParameterError ""
	if not data.mail?
		return callback new restify.InvalidArgumentError "You need to specify a mail."
	if not data.name?
		return callback new restify.InvalidArgumentError "You need to specify a name."
	if not data.pass?
		return callback new restify.InvalidArgumentError "You need to specify a pass."
	if not data.platform? or data.platform isnt admin.platform_admin
		return callback new restify.InvalidArgumentError "You need to specify your platform name."
	data:
		email: data.mail
		pass: data.pass
		name: data.name
		platform: data.platform
	db.users.register data, (err, user) -> 
		console.log "db_platforms_users register err", err
		console.log "db_platforms_users register user", user
		return callback err if err
		returnedUser = mail:user.mail, name:user.name, date_inscr:user.date_inscr
		return callback null, returnedUser

# mail - Required - string
# The mail of the user.
# data.platform - Required - string
# The name of your platform.
exports.remove = (mail, data, admin, callback) ->
	console.log "db_platforms_users remove mail", mail
	console.log "db_platforms_users remove data", data
	console.log "db_platforms_users remove admin", admin
	if not data?
		return callback new restify.MissingParameterError ""
	if not data.platform? or data.platform isnt admin.platform_admin
		return callback new restify.InvalidArgumentError "You need to specify your platform name."
	if not mail?
		return callback new restify.InvalidArgumentError "You need to specify a mail."

	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback new restify.InvalidArgumentError "You need to specify a valid mail." unless iduser
		return callback err if err
		db.users.remove iduser, (err) -> 
			return callback err if err
			callback()


# mail - Required - string
# The mail of the user.
# data.platform - Required - string
# The name of your platform.
exports.getDetails = (mail, data, admin, callback) ->
	console.log "db_platforms_users getDetails mail", mail
	console.log "db_platforms_users getDetails data", data
	console.log "db_platforms_users getDetails admin", admin
	if not data?
		return callback new restify.MissingParameterError ""
	if not data.platform? or data.platform isnt admin.platform_admin
		return callback new restify.InvalidArgumentError "You need to specify your platform name."
	if not mail?
		return callback new restify.InvalidArgumentError "You need to specify a mail."

	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback new restify.InvalidArgumentError "You need to specify a valid mail." unless iduser
		return callback err if err
		db.users.get iduser, (err, user) ->
			return callback err if err
			if not user.profile.platform? or user.profile.platform isnt admin.platform_admin
				return callback new restify.InvalidArgumentError "You need to specify a valid mail."
			else
				db.users.getApps user.profile.id, (err, appkeys) ->
					return callback err if err
					user.apps = appkeys
					return callback null, user


# data.platform - Required - string
# The name of your platform.
exports.getAllDetails = (data, admin, callback) ->
	console.log "db_platforms_users getAllDetails data", data
	console.log "db_platforms_users getAllDetails admin", admin
	if not data?
		return callback new restify.MissingParameterError ""
	if not data.platform? or data.platform isnt admin.platform_admin
		return callback new restify.InvalidArgumentError "You need to specify your platform name."
	
	db.redis.hgetall 'u:mails', (err, users) =>
		return callback err if err
		platforms_users = []
		tasks = []
		for mail, iduser of users
			do (iduser) ->
				tasks.push (cb) -> 
					db.users.get iduser, (err, user) -> 
						return cb err if err
						if user.profile.platform? and user.profile.platform is admin.platform_admin
							db.users.getApps user.profile.id, (err, appkeys) ->
								return callback err if err
								user.apps = appkeys
								platforms_users.push user
						cb()
		async.series tasks, (err) ->
			return callback err if err
			return callback null, platforms_users

