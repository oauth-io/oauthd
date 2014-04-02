# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# Licensed under the MIT license.

'use strict'

async = require 'async'
restify = require 'restify'
crypto = require 'crypto'

{config,check,db} = shared = require '../shared'

exports.raw = ->

	# * Registering a user coming from heroku cloud
	# 
	registerHerokuAppUser = (data, callback) ->
		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			key = db.generateUid()
			heroku_app_name = data.heroku_id.split("@")[0]
			heroku_url = 'https://oauth.io/auth/heroku/' + heroku_app_name
			date_now = (new Date).getTime()
			arr = ['mset', prefix+'mail', data.heroku_id,
					prefix+'heroku_id', data.heroku_id,
					prefix+'heroku_name', heroku_app_name,
					prefix+'heroku_url', heroku_url,
					prefix+'current_plan', data.plan,
					prefix+'key', key,
					prefix+'validated', 1,
					prefix+'date_inscr', date_now,
					prefix+'date_validate', date_now ]

			db.redis.multi([
					arr,
					[ 'hset', 'u:mails', data.heroku_id, val ],
					[ 'hset', 'u:heroku_id', data.heroku_id, val ],
					[ 'hset', 'u:heroku_name', heroku_app_name, val ]
					[ 'hset', 'u:heroku_url', heroku_url, val ]
				]).exec (err, res) ->
					return callback err if err
					user = id:val, mail:data.heroku_id, heroku_id:data.heroku_id, heroku_name:heroku_app_name, heroku_url:heroku_url, current_plan:data.plan, key:key, date_inscr:date_now, date_validate:date_now
					shared.emit 'user.register', user
					shared.emit 'heroku_user.register', user
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
			# console.log "Unable to authenticate user"
			# console.log "req.authorization", req.authorization
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
		idresource = decodeURIComponent(req.body.id)
		get_resource_by_id idresource, (err, resource) =>
			res.send 404, "Not found" if err
			# not used for now
			# req.session.resource = resource
			# req.session.email = req.body.email
			pre_token = idresource + ":" + config.heroku.sso_salt + ":" + req.body.timestamp
			shasum = crypto.createHash("sha1")
			shasum.update pre_token
			token = shasum.digest("hex")

			unless req.body.token is token
				res.send 403, "Token Mismatch" 
				return
			time = (new Date().getTime() / 1000) - (2 * 60)
			if parseInt(req.body.timestamp) < time
				res.send 403, "Timestamp Expired"
				return

			res.setHeader 'Content-Type', 'text/html'
			shared.auth.generateToken id:resource.id, mail:resource.mail, validated:true, (err, token) =>
				return next err if err
				expireDate = new Date((new Date - 0) + 3600*36 * 1000)
				# We need to send the app name to fill the heroku navbar
				# We need to fil the heroku nav data cookie
				cookies = [
					'accessToken=%22' + token + '%22; Path=/; Expires=' + expireDate.toUTCString()
					'heroku-nav-data=' + req.body['nav-data'] + '; Path=/; Expires=' + expireDate.toUTCString()
					'heroku-body-app=%22' + req.body.app + '%22; Path=/; Expires=' + expireDate.toUTCString()
					]
				res.setHeader 'Set-Cookie', cookies
				res.setHeader 'Location', config.host_url + '/key-manager'

				next()
				return

	checkPlan = (req, res, next) ->
		resource_plan = "bootstrap"
		plan_ask = db.plans[req.body.plan]
		if plan_ask isnt undefined
			resource_plan = plan_ask.id
		if req.body.region isnt undefined and req.body.region is 'fr'
			resource_plan += "_fr"
		req.body.plan = resource_plan
		next()
		return

	subscribeEvent = (resource, plan) ->
		if plan isnt "bootstrap"
			shared.emit 'heroku_user.subscribe', resource, plan

	sso_login = (req, res, next) ->
		# res.setHeader 'Location', '/'
		res.setHeader 'Location', '/key-manager'
		res.send 301
		return

	get_resource_by_id = (hid, callback) ->
		db.redis.hget 'u:heroku_id', hid, (err, idresource) ->
			return callback err if err or idresource is 'undefined'
			prefix = 'u:' + idresource + ':'
			db.redis.mget [ prefix + 'mail',
				prefix + 'heroku_id',
				prefix + 'heroku_name',
				prefix + 'heroku_url',
				prefix + 'current_plan',
				prefix + 'key',
				prefix + 'validated',
				prefix + 'date_inscr',
				prefix + 'date_validate' ]
			, (err, replies) ->
				return callback err if err
				resource =
					id:idresource,
					mail:replies[0],
					heroku_id: replies[1],
					heroku_name: replies[2],
					heroku_url: replies[3],
					current_plan: replies[4],
					key: replies[5],
					validated: replies[6],
					date_inscr:replies[7],
					date_validate:replies[8]
				for field of resource
					resource[field] = '' if resource[field] == 'undefined'
				return callback err if err
				return callback null, resource

	destroy_resource = (resource, callback) ->
		idresource = resource.id
		return callback err if idresource is 'undefined'
		prefix = 'u:' + idresource + ':'
		db.redis.get prefix+'heroku_id', (err, heroku_id) ->
			return callback err if err or heroku_id is 'undefined'
			return callback new check.Error 'Unknown user' unless heroku_id
			db.users.getApps idresource, (err, appkeys) ->
				tasks = []
				for key in appkeys
					do (key) ->
						tasks.push (cb) -> db.apps.remove key, cb
				async.series tasks, (err) ->
					return callback err if err

					db.redis.multi([
						[ 'hdel', 'u:mails', resource.mail ]
						[ 'hdel', 'u:heroku_id', heroku_id ]
						[ 'hdel', 'u:heroku_name', resource.heroku_name ]
						[ 'hdel', 'u:heroku_url', resource.heroku_url ]
						[ 'del', prefix + 'mail',
							prefix + 'heroku_id',
							prefix + 'heroku_name',
							prefix + 'heroku_url',
							prefix + 'current_plan',
							prefix + 'key',
							prefix + 'validated',
							prefix + 'date_inscr',
							prefix + 'date_validate',
							prefix + 'apps' ]
					]).exec (err, replies) ->
						return callback err if err
						shared.emit 'user.remove', mail:resource.mail
						shared.emit 'heroku_user.remove', mail:resource.mail
						callback null, resource

	# Plan Change
	changePlan = (req, res, next) =>
		idresource = decodeURIComponent(req.params.id)
		get_resource_by_id idresource, (err, resource) =>
			res.send 404, "Not found" if err
			user_id = resource.id
			prefix = "u:#{user_id}:"
			db.redis.mset [
				prefix + 'current_plan', req.body.plan
			], (err) ->
				res.send 404, "Cannot change plan" if err
				subscribeEvent resource, req.body.plan
				res.send "ok"

	# * Deprovision
	deprovisionResource = (req, res, next) =>
		idresource = decodeURIComponent(req.params.id)
		get_resource_by_id idresource, (err, resource) =>
			res.send 404, "Not found" if err
			destroy_resource resource, (err, resource) =>
				res.send 404, "Cannot deprovision resource" if err
				shared.emit 'heroku_user.unsubscribe', resource
				res.send("ok")

	createDefaultApp = (userid, callback) =>
		appreq = 
			body: 
				domains:["localhost"]
				name:"Heroku default app"
			user:
				id:userid
		db.apps.create appreq, (err, app) ->
			shared.emit 'app.create', appreq, app
			return callback err if err
			return callback null, app
		
	# * Provisioning
	# A private resource is created for each app that adds your add-on.
	# Any provisioned resource should be referenced by a unique URL, 
	# which is how the customer’s app consumes the resource.
	# 
	###### RETURN a json containing
	# - the ID
	# - a config var hash containing a URL to consume the service
	provisionResource = (req, res, next) =>
		# console.log "provisionResource req.body", req.body
		data =
  			heroku_id: req.body.heroku_id
  			plan: req.body.plan
  			callback_url: req.body.callback_url
  		# callback_url unused for the moment

		registerHerokuAppUser data, (err, user) =>
			# console.log "user", user
			res.send 404 if err
			createDefaultApp user.id, (err, app) =>
				# not working
				# db.users.getApps user.id, (err, appkeys) ->
				# 	console.log "appkeys", appkeys
				subscribeEvent user, user.current_plan
				result = 
					id: 
						user.heroku_id 
					config: 
						OAUTHIO_PUBLIC_KEY: app.key
						OAUTHIO_URL: user.heroku_url
				stringifyResult = JSON.stringify(result)
				# console.log "stringifyResult", stringifyResult
				res.setHeader 'Content-Type', 'application/json'
				res.end stringifyResult

	# Heroku will call your service via a POST to /heroku/resources 
	# in order to provision a new resource.
	@server.post new RegExp('/heroku/resources'), restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), checkPlan, provisionResource
	@server.get '/heroku/sso/:id', restify.authorizationParser(), restify.bodyParser({ mapParams: false }), sso_auth, sso_login
	# Heroku will call your service via a PUT to /heroku/resources/:id 
	# in order to change the plan.
	@server.put '/heroku/resources/:id', restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), checkPlan, changePlan
	@server.del '/heroku/resources/:id', restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), deprovisionResource
	@server.post '/heroku/sso/login', restify.authorizationParser(), restify.bodyParser({ mapParams: false }), sso_auth, sso_login
	