# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

restify = require 'restify'
async = require 'async'
{config,check,db} = shared = require '../shared'

# Data:
# name - Required - string
# The name of the user.
# mail - Required - string
# The mail of the user.
# pass - Required - string
# The password of the user.
exports.create = (data, platform, callback) ->
	console.log "db_platforms_users create"
	console.log "db_platforms_users create data", data
	console.log "db_platforms_users create platform", platform
	console.log ""
	if not data?
		return next new restify.MissingParameterError "Missing data."
	if not data.mail?
		return callback new restify.InvalidArgumentError "You need to specify a mail."
	if not data.name?
		return callback new restify.InvalidArgumentError "You need to specify a name."
	if not data.pass?
		return callback new restify.InvalidArgumentError "You need to specify a pass."
	db_user_data = 
		mail: data.mail
		pass: data.pass
		name: data.name
		platform: platform
	db.users.register db_user_data, (err, user) -> 
		return callback err if err

		returnedUser = mail:user.mail, name:user.name, date_inscr:user.date_inscr, platform:user.platform
		return callback null, returnedUser

exports.remove = (platform_user, callback) ->
	console.log "db_platforms_users remove"
	console.log "db_platforms_users remove platform_user", platform_user
	console.log ""
	db.users.remove platform_user.id, (err) -> 
		return callback err if err
		callback()


exports.getDetails = (platform_user, callback) ->
	console.log "db_platforms_users getDetails"
	console.log "db_platforms_users getDetails platform_user", platform_user
	console.log ""
	db.users.getApps platform_user.id, (err, appkeys) ->
		return callback err if err
		platform_user.apps = appkeys
		return callback null, platform_user


exports.getAllDetails = (admin, callback) ->
	console.log "db_platforms_users getAllDetails"
	console.log "db_platforms_users getAllDetails admin", admin	
	console.log ""
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
						else
							cb()
		async.series tasks, (err) ->
			return callback err if err
			return callback null, platforms_users

