# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# Licensed under the MIT license.

'use strict'

async = require 'async'
restify = require 'restify'

{config,check,db} = shared = require '../shared'

exports.raw = ->

	# * Registering a user coming from heroku cloud
	# 
	registerHerokuAppUser = (data, callback) ->
		date_inscr = (new Date).getTime()

		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			key = db.generateUid()
			real_heroku_id = data.heroku_id.split("@")[0]
			heroku_url = 'https://oauth.io/auth/heroku/' + real_heroku_id
			
			arr = ['mset', prefix+'mail', "",
					prefix+'key', key,
					prefix+'validated', 1,
					prefix+'date_inscr', date_inscr,
					prefix+'date_validate', (new Date).getTime(),
					prefix+'heroku_id', real_heroku_id,
					prefix+'heroku_name', data.heroku_id,
					prefix+'heroku_url', heroku_url,
					prefix+'current_plan', data.plan ]

			db.redis.multi([
					arr,
					[ 'hset', 'u:heroku_url', heroku_url, val ],
					[ 'hset', 'u:heroku_id', real_heroku_id, val ]
				]).exec (err, res) ->
					return callback err if err
					user = id:val, heroku_id:real_heroku_id, heroku_url:heroku_url, heroku_name:data.heroku_id,current_plan:data.plan, date_inscr:date_inscr, key:key
					# shared.emit 'user.register', user
					return callback null, user

	# * Authentication
	# config.heroku contains :
	# - the heroku_user
	# - the heroku_password
	# When you run kensa init to generate an add-on manifest, 
	# a password (auto-generated) is filled in for you. 
	# You can use the defaults, or change these values to anything you like.	
	# 
	###### RETURN
	# Your service is expected to authenticate all provisioning calls 
	# with the add-on id and password found in the add-on manifest. 
	# A failed authentication should return 401 Not Authorized.			
	basic_auth = (req, res, next) ->
		if req.authorization and req.authorization.scheme is 'Basic' and req.authorization.basic.username is config.heroku.heroku_user and req.authorization.basic.password is config.heroku.heroku_password
			return next()
		else
			console.log "Unable to authenticate user"
			console.log "req.authorization", req.authorization
			res.header "WWW-Authenticate", "Basic realm=\"Admin Area\""
			res.send 401, "Authentication required"
			return

	# Singe-Sign On authentification
	# Receive the request, confirms that the token matches 
	# and confirm that the timestamp is fresh
	# token = sha1(id + ':' + salt + ':' + timestamp)
	# 
	# Then set a cookie in the user’s browser to indicate that they are authenticated, 
	# and then redirect to the admin panel for the resource.
	sso_auth = (req, res, next) ->
		console.log "req.params", req.params
		 
		pre_token = req.params.id + ":" + config.heroku.sso_salt + ":" + req.params.timestamp
		shasum = crypto.createHash("sha1")
		shasum.update pre_token
		token = shasum.digest("hex")

		unless req.param.token is token
			res.send 403, "Token Mismatch" 
			return
		time = (new Date().getTime() / 1000) - (2 * 60)
		if parseInt(req.param.timestamp) < time
			res.send 403, "Timestamp Expired"
			return

		res.cookie "heroku-nav-data", req.param("nav-data")
		req.session.resource = get_resource_by_id(id)
		req.session.email = req.param.email
		next()
		return

	get_resource_by_id = (data, callback) ->
		db.redis.hget 'u:heroku_id', data, (err, iduser) ->
			return callback err if err or iduser is 'undefined'
			prefix = 'u:' + iduser + ':'
			db.redis.mget [ prefix + 'mail',
				prefix + 'date_inscr',
				prefix + 'key',
				prefix + 'heroku_id',
				prefix + 'heroku_name',
				prefix + 'heroku_url',
				prefix + 'validated' ]
			, (err, replies) ->
				return callback err if err
				resource =
					id:iduser,
					mail:replies[0],
					date_inscr:replies[1],
					key: replies[2],
					real_heroku_id: replies[3],
					heroku_name: replies[4],
					heroku_url: replies[5],
					validated: replies[6]
				for field of resource
					resource[field] = '' if resource[field] == 'undefined'

				return callback err if err
				return callback null, resource

	destroy_resource = (iduser, callback) ->
		return callback err if iduser is 'undefined'
		prefix = 'u:' + iduser + ':'
		db.redis.get prefix+'heroku_id', (err, heroku_id) ->
			return callback err if err or heroku_id is 'undefined'
			return callback new check.Error 'Unknown user' unless heroku_id
			db.users.getApps iduser, (err, appkeys) ->
				tasks = []
				for key in appkeys
					do (key) ->
						tasks.push (cb) -> db.apps.remove key, cb
				async.series tasks, (err) ->
					return callback err if err

					db.redis.multi([
						[ 'hdel', 'u:heroku_id', heroku_id ]
						[ 'del', prefix+'mail', prefix+'date_inscr', prefix+'key', 
								prefix+'heroku_id', prefix+'heroku_name', prefix+'heroku_url', 
								prefix+'validated', prefix+'date_validate', prefix+'current_plan', prefix+'apps' ]
					]).exec (err, replies) ->
						return callback err if err
						# shared.emit 'user.remove', mail:mail
						callback()

	# Plan Change
	changePlan = (req, res, next) =>
		console.log "req.body", req.body
		console.log "req.params", req.params
		get_resource_by_id req.params.id, (err, resource) =>
			res.send 404, "Not found" if err
			user_id = resource.id
			prefix = "u:#{user_id}:"
			db.redis.mset [
				prefix + 'current_plan', req.body.plan
			], (err) ->
				return callback err if err
				res.send "ok"

	# * Deprovision
	deprovisionResource = (req, res, next) =>
		get_resource_by_id req.params.id, (err, resource) =>
			res.send 404, "Not found" if err
			destroy_resource resource.id, (err, resource) =>
				res.send 404, "Cannot deprovision resource" if err
				res.send("ok")

	# * Provisioning
	# A private resource is created for each app that adds your add-on.
	# Any provisioned resource should be referenced by a unique URL, 
	# which is how the customer’s app consumes the resource.
	# 
	###### RETURN a json containing
	# - the ID
	# - a config var hash containing a URL to consume the service
	provisionResource = (req, res, next) =>
		data =
  			heroku_id: req.body.heroku_id
  			plan: req.body.plan
		registerHerokuAppUser data, (err, user) =>
			console.log "user", user
			res.send 404 if err
			result = 
				id: 
					user.heroku_id
				config: 
					OAUTHIO_URL: user.heroku_url
			res.setHeader 'Content-Type', 'application/json'
			res.end JSON.stringify(result)

	# Heroku will call your service via a POST to /heroku/resources 
	# in order to provision a new resource.
	@server.post new RegExp('/heroku/resources'), restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), provisionResource
	@server.put new RegExp('/heroku/resources/:id'), restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), changePlan
	@server.del '/heroku/resources/:id', restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), deprovisionResource
	@server.post new RegExp('/heroku/sso'), restify.authorizationParser(), restify.bodyParser({ mapParams: false }), sso_auth
	@server.get new RegExp('/heroku/sso/:id'), restify.authorizationParser(), restify.bodyParser({ mapParams: false }), sso_auth
