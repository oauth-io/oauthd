# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

restify = require 'restify'
async = require 'async'
{config,check,db} = shared = require '../shared'

#### APPS

# data.name - Required - string
# The new name of the application, 3 to 50 chars.
# data.domains - Required - array of strings
# Array of valid urls scheme/domain/port/path. You can choose the url detail level to use.
exports.create = (body, platform_user, admin, callback) ->
	# console.log "db_platforms_apps create"
	# console.log "db_platforms_apps create body", body
	# console.log "db_platforms_apps create platform_user", platform_user
	# console.log "db_platforms_apps create admin", admin
	if not body?
		return callback new restify.MissingParameterError "Missing body."
	if not body.name?
		return callback new restify.InvalidArgumentError "You need to specify the new name of the application."
	if not body.domains?
		return callback new restify.InvalidArgumentError "You need to specify an array of valid urls scheme/domain/port/path."
	data = 
		name: body.name
		domains: body.domains
	db.apps.create data, platform_user, (err, app) ->
		return callback err if err
		shared.emit 'app.create', platform_user, app
		app = name:app.name, key:app.key, domains:app.domains
		return callback null, app


# key - Required - string
# The app's public key
exports.getDetails = (key, callback) ->
	# console.log "db_platforms_apps getDetails"
	# console.log "db_platforms_apps getDetails key", key
	console.log ""
	async.parallel [
		(cb) -> db.apps.get key, cb
		(cb) -> db.apps.getDomains key, cb
		(cb) -> db.apps.getKeysets key, cb
	], (err, res) ->
		return callback err if err
		app = name:res[0].name, key:res[0].key, secret:res[0].secret, domains:res[1], keysets:res[2]
		return callback null, app


exports.update = (key, body, callback) ->
	# console.log "db_platforms_apps update"
	# console.log "db_platforms_apps update key", key
	# console.log "db_platforms_apps update body", body
	if not body?
		return callback new restify.MissingParameterError "Missing body."
	data = {}
	if body.name?
		data.name = body.name
	if body.domains?
		data.domains = body.domains
	db.apps.update key, data, (err) ->
		return callback err if err
		db.platforms_apps.getDetails key, (err, app) ->
			return callback err if err
			return callback null, app

	
exports.remove = (key, platform_user, callback) ->
	# console.log "db_platforms_apps remove"
	# console.log "db_platforms_apps remove key", key
	# console.log "db_platforms_apps remove platform_user", platform_user
	db.apps.get key, (err, app) ->
		return callback err if err
		db.apps.remove key, (err, r) ->
			return callback err if err
			shared.emit 'app.remove', platform_user, app
			return callback null

exports.resetKeys = (key, callback) ->
	# console.log "db_platforms_apps resetKeys"
	# console.log "db_platforms_apps resetKeys key", key
	db.apps.resetKey key, (err, keys) ->
		return callback err if err
		db.platforms_apps.getDetails keys.key, (err, app) ->
			return callback err if err
			return callback null, app


#### DOMAINS

exports.listDomain = (key, callback) ->
	# console.log "db_platforms_apps listDomain"
	# console.log "db_platforms_apps listDomain key", key
	db.apps.getDomains key, (err, domains) ->
		return callback err if err
		return callback null, domains

exports.updateDomains = (key, body, callback) ->
	# console.log "db_platforms_apps updateDomains"
	# console.log "db_platforms_apps updateDomains key", key
	# console.log "db_platforms_apps updateDomains body", body
	if not body?
		return callback new restify.MissingParameterError "Missing body."
	if not body.domains?
		return callback new restify.InvalidArgumentError "You need to specify an array of valid urls scheme/domain/port/path."
	db.apps.updateDomains key, body.domains, (err) ->
		return callback err if err
		db.platforms_apps.listDomain key, (err, domains) ->
			return callback err if err
			return callback null, domains

exports.addDomain = (key, domain, callback) ->
	# console.log "db_platforms_apps addDomain"
	# console.log "db_platforms_apps addDomain key", key
	# console.log "db_platforms_apps addDomain domain", domain
	if not domain?
		return callback new restify.InvalidArgumentError "You need to specify a valid urls scheme/domain/port/path."
	db.apps.addDomain key, domain, (err) ->
		return callback err if err
		db.platforms_apps.listDomain key, (err, domains) ->
			return callback err if err
			return callback null, domains

exports.removeDomain = (key, domain, callback) ->
	# console.log "db_platforms_apps removeDomain"
	# console.log "db_platforms_apps removeDomain key", key
	# console.log "db_platforms_apps removeDomain domain", domain
	if not domain?
		return callback new restify.InvalidArgumentError "You need to specify a valid urls scheme/domain/port/path."
	db.apps.remDomain key, domain, (err) ->
		return callback err if err
		db.platforms_apps.listDomain key, (err, domains) ->
			return callback err if err
			return callback null, domains


#### KEYSETS

exports.getKeysets = (key, callback) ->
	# console.log "db_platforms_apps getKeysets"
	# console.log "db_platforms_apps getKeysets key", key
	db.apps.getKeysets key, (err, keysets) ->
		return callback err if err
		return callback null, keysets

exports.getKeyset = (key, provider, callback) ->
	# console.log "db_platforms_apps getKeyset"
	# console.log "db_platforms_apps getKeyset key", key
	# console.log "db_platforms_apps getKeyset provider", provider
	if not provider?
		return callback new restify.InvalidArgumentError "You need to specify a valid provider name."
	db.apps.getKeyset key, provider, (err, keyset) ->
		return callback err if err
		if (k for own k of keyset.parameters).length is 0
			return callback new check.Error 'provider', 'You have no keyset for ' + provider
		return callback null, keyset

exports.addKeyset = (key, provider, body, callback) ->
	# console.log "db_platforms_apps addKeyset"
	# console.log "db_platforms_apps addKeyset key", key
	# console.log "db_platforms_apps addKeyset provider", provider
	# console.log "db_platforms_apps addKeyset body", body
	if not provider?
		return callback new restify.InvalidArgumentError "You need to specify a valid provider name."
	if not body?
		return callback new restify.InvalidArgumentError "Missing body."
	if not body.parameters?
		return callback new restify.InvalidArgumentError "You need to specify the parameters of the keyset, according to the provider's configuration."
	if not body.response_type?
		return callback new restify.InvalidArgumentError "You need to specify the response type, it can be \"token\" (client-side), \"code\" (server-side), or \"both\""
	data = 
		parameters: body.parameters
		response_type: body.response_type
	db.apps.addKeyset key, provider, data, (err) ->
		return callback err if err
		db.apps.getKeyset key, provider, (err, keyset) ->
			return callback err if err
			return callback null, keyset

exports.removeKeyset = (key, provider, callback) ->
	# console.log "db_platforms_apps removeKeyset"
	# console.log "db_platforms_apps removeKeyset key", key
	# console.log "db_platforms_apps removeKeyset provider", provider
	if not provider?
		return callback new restify.InvalidArgumentError "You need to specify a valid provider name."
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.apps.remKeyset key, provider, (err) -> 
			return callback err if err
			db.redis.exists 'a:' + idapp + ':k:' + provider, (err, res) ->
				return callback err if err
				if res
					return callback new restify.InternalError "Error: keyset was not removed."
				else
					return callback null


