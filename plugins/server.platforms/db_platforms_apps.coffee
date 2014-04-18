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
exports.create = (data, platform_user, admin, callback) ->
	console.log "db_platforms_apps create"
	console.log "db_platforms_apps create data", data
	console.log "db_platforms_apps create platform_user", platform_user
	console.log "db_platforms_apps create admin", admin
	console.log ""
	if not data.name?
		return callback new restify.InvalidArgumentError "You need to specify the new name of the application."
	if not data.domains?
		return callback new restify.InvalidArgumentError "You need to specify an array of valid urls scheme/domain/port/path."
	
	db.apps.create data, platform_user, (err, res) ->
		return next(err) if err
		plugins.data.emit 'app.create', req, res
		app = name:res.name, key:res.key, domains:res.domains
		return callback null, app


# key - Required - string
# The app's public key
exports.getDetails = (key, platform_user, admin, callback) ->
	console.log "db_platforms_apps getDetails"
	console.log "db_platforms_apps getDetails key", key
	console.log "db_platforms_apps getDetails platform_user", platform_user
	console.log "db_platforms_apps getDetails admin", admin
	console.log ""
	
	



exports.update = (key, data, admin, callback) ->

exports.remove = (key, data, admin, callback) ->

exports.resetKeys = (key, data, admin, callback) ->


#### DOMAINS

exports.listDomain = (key, data, admin, callback) ->


exports.updateDomains = (key, data, admin, callback) ->


exports.addDomain = (key, domain, data, admin, callback) ->


exports.removeDomain = (key, domain, data, admin, callback) ->



#### KEYSETS

exports.getKeysets = (key, data, admin, callback) ->


exports.getKeyset = (key, provider, data, admin, callback) ->


exports.addKeyset = (key, provider, data, admin, callback) ->


exports.removeKeyset = (key, provider, data, admin, callback) ->



