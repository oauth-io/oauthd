# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

restify = require 'restify'
async = require 'async'
{config,check,db} = shared = require '../shared'

# Body:
# name - Required - string
# The name of the user.
# mail - Required - string
# The mail of the user.
# pass - Required - string
# The password of the user.
exports.create = (body, platform, callback) ->
	# console.log "db_platforms_users create"
	# console.log "db_platforms_users create body", body
	# console.log "db_platforms_users create platform", platform
	if not body?
		return next new restify.MissingParameterError "Missing body."
	if not body.mail?
		return callback new restify.InvalidArgumentError "You need to specify a email."
	if not body.name?
		return callback new restify.InvalidArgumentError "You need to specify a name."
	if not body.pass?
		return callback new restify.InvalidArgumentError "You need to specify a pass."
	data = 
		mail: body.mail
		pass: body.pass
		name: body.name
		platform: platform
	db.users.register data, (err, user) -> 
		return callback err if err
		returnedUser = mail:user.mail, name:user.name, date_inscr:user.date_inscr, platform:user.platform
		return callback null, returnedUser


exports.remove = (platform_user, callback) ->
	# console.log "db_platforms_users remove"
	# console.log "db_platforms_users remove platform_user", platform_user
	db.users.remove platform_user.id, (err) -> 
		return callback err if err
		callback()


exports.getDetails = (platform_user, callback) ->
	# console.log "db_platforms_users getDetails"
	# console.log "db_platforms_users getDetails platform_user", platform_user
	db.users.getApps platform_user.id, (err, appkeys) ->
		return callback err if err
		resUser = 
			mail:platform_user.mail
			name:platform_user.name
			date_inscr:platform_user.date_inscr
			location:platform_user.location
			company:platform_user.company
			website:platform_user.website
			platform:platform_user.platform
			apps:appkeys
		return callback null, resUser


exports.getAllDetails = (admin, callback) ->
	# console.log "db_platforms_users getAllDetails"
	# console.log "db_platforms_users getAllDetails admin", admin	
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
								resUser = 
									mail:user.profile.mail
									name:user.profile.name
									date_inscr:user.profile.date_inscr
									location:user.profile.location
									company:user.profile.company
									website:user.profile.website
									platform:user.profile.platform
									apps:appkeys
								platforms_users.push resUser
								cb()
						else
							cb()
		async.series tasks, (err) ->
			return callback err if err
			return callback null, platforms_users

