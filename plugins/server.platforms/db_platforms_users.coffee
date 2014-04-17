# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

restify = require 'restify'
{config,check,db} = shared = require '../shared'

# name - Required - string
# The name of the user.
# mail - Required - string
# The mail of the user.
# pass - Required - string
# The password of the user.
# platform - Required - string
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
# platform - Required - string
# The name of your platform.
exports.remove = (mail, data, admin, callback) ->
	console.log "db_platforms_users remove data", data
	console.log "db_platforms_users remove admin", admin
	if not data?
		return callback new restify.MissingParameterError ""
	if not mail?
		return callback new restify.InvalidArgumentError "You need to specify a mail."
	if not data.platform? or data.platform isnt admin.platform_admin
		return callback new restify.InvalidArgumentError "You need to specify your platform name."

	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback new restify.InvalidArgumentError "You need to specify a valid mail." unless iduser
		db.users.remove iduser, (err) -> 
			return callback err if err
			callback()


