# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

'use strict'

restify = require 'restify'
{config,check,db} = shared = require '../shared'

exports.setup = (callback) ->

	@db.platforms_users = require './db_platforms_users'
	

	#### PLATFORMS USERS

	# create a platform user
	@server.post @config.base_api + '/platforms/:platform/users', @auth.platformAdm, (req, res, next) =>
		@db.platforms_users.create req.body.data, req.params.platform, (err, user) =>
			return next(err) if err
			res.send user
			next()

	# remove a platform user
	@server.del @config.base_api + '/platforms/:platform/users/:mail', @auth.platformAdm, @auth.platformManageUser, (req, res, next) =>
		@db.platforms_users.remove req.platform_user, (err, user) =>
			return next(err) if err
			res.send 200, "User removed."
			next()

	# get info on a platform user
	@server.get @config.base_api + '/platforms/:platform/users/:mail', @auth.platformAdm, @auth.platformManageUser, (req, res, next) =>
		@db.platforms_users.getDetails req.platform_user, (err, user) =>
			return next(err) if err
			res.send user
			next()

	# get infos on all the platform users
	@server.get @config.base_api + '/platforms/:platform/users', @auth.platformAdm, (req, res, next) =>
		@db.platforms_users.getAllDetails req.admin, (err, users) =>
			return next(err) if err
			res.send users
			next()


	#### PLATFORMS USERS APPs

	# create an application
	@server.post @config.base_api + '/platforms/:platform/users/:mail/apps', @auth.platformAdm, @auth.platformManageUser, (req, res, next) =>
		@db.platforms_apps.create req.body.data, req.platform_user, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()

	# get an application details
	@server.get @config.base_api + '/platforms/:platform/users/:mail/apps/:key', @auth.platformAdm, @auth.platformManageUser, @auth.checkPlatformUserHasAccessToAppKey, (req, res, next) =>
		@db.platforms_apps.getDetails req.params.key, req.platform_user, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()

	# update an application details
	@server.post @config.base_api + '/platforms/:platform/users/:mail/apps/:key', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.update req.params.key, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()
	
	# delete an application 
	@server.del @config.base_api + '/platforms/:platform/users/:mail/apps/:key', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.remove req.params.key, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send 200, "Application removed."
			next()

	# reset an app's public and secret keys.
	@server.post @config.base_api + '/platforms/:platform/users/:mail/apps/:key/reset', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.resetKeys req.params.key, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()


	#### PLATFORMS USERS APPS DOMAINS

	# list valid domains for an app.
	@server.get @config.base_api + '/platforms/:platform/users/:mail/apps/:key/domains', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.listDomain req.params.key, req.body.data, req.admin, (err, domains) =>
			return next(err) if err
			res.send domains
			next()

	# update valid domains for an app.
	@server.post @config.base_api + '/platforms/:platform/users/:mail/apps/:key/domains', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.updateDomains req.params.key, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()
	
	# add a valid domain for an app.
	@server.post @config.base_api + '/platforms/:platform/users/:mail/apps/:key/domains/:domain', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.addDomain req.params.key, req.params.domain, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()
	
	# remove a valid domain for an app.
	@server.del @config.base_api + '/platforms/:platform/users/:mail/apps/:key/domains/:domain', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.removeDomain req.params.key, req.params.domain, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()

	
	#### PLATFORMS USERS APPs KEYSETs

	# list keysets for an app.
	@server.get @config.base_api + '/platforms/:platform/users/:mail/apps/:key/keysets', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.getKeysets req.params.key, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()
	
	# get a keyset for an app and a provider. Returns null if the keyset does not exists.
	@server.get @config.base_api + '/platforms/:platform/users/:mail/apps/:key/keysets/:provider', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.getKeyset req.params.key, req.params.provider, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()
	
	# add or update a keyset for an app and a provider. If the keyset already exists, it will be replaced.
	@server.post @config.base_api + '/platforms/:platform/users/:mail/apps/:key/keysets/:provider', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.addKeyset req.params.key, req.params.provider, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()

	# remove a keyset from an app by provider's name.
	@server.del @config.base_api + '/platforms/:platform/users/:mail/apps/:key/keysets/:provider', @auth.platformAdm, (req, res, next) =>
		@db.platforms_apps.removeKeyset req.params.key, req.params.provider, req.body.data, req.admin, (err, app) =>
			return next(err) if err
			res.send app
			next()


	# EVENTS

	@on 'platform.remove', (platform) =>
		if platform? and platform.name? and platform.id?
			db.platforms_admins.removeAdminsOfPlatform platform.name, (err) ->
				console.log "Error removing admins of platform " + platform.name + " with id " + platform.id + ".", err
		else
			console.log "Missing informations to remove admins of platform." 

	callback()