# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

'use strict'

restify = require 'restify'
crypto = require 'crypto'

{config,check,db} = shared = require '../shared'

exports.raw = ->

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
			console.log "Unable to authenticate user."
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
		idresource = decodeURIComponent(req.body.id)
		db.heroku.get_resource_by_id idresource, (err, resource) =>
			res.send 404, "Not found" if err
			# not used for now
			# req.session.resource = resource
			# req.session.email = req.body.email
			if not err
				pre_token = idresource + ":" + config.heroku.sso_salt + ":" + req.body.timestamp
				shasum = crypto.createHash("sha1")
				shasum.update pre_token
				token = shasum.digest("hex")

				unless req.body.token is token
					res.send 403, "Token Mismatch" 
					return
				time = (new Date().getTime() / 1000) - (4 * 60)
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

	sso_login = (req, res, next) ->
		# res.setHeader 'Location', '/'
		res.setHeader 'Location', '/key-manager'
		res.send 301
		return

	# Plan Change
	changePlan = (req, res, next) =>
		idresource = decodeURIComponent(req.params.id)
		db.heroku.get_resource_by_id idresource, (err, resource) =>
			res.send 404, "Not found" if err
			if not err
				user_id = resource.id
				prefix = "u:#{user_id}:"
				db.redis.mset [
					prefix + 'current_plan', req.body.plan
				], (err) ->
					res.send 404, "Cannot change plan." if err
					if not err
						subscribeEvent resource, req.body.plan
						res.send "ok"

	# * Deprovision
	deprovisionResource = (req, res, next) =>
		idresource = decodeURIComponent(req.params.id)
		db.heroku.get_resource_by_id idresource, (err, resource) =>
			res.send 404, "Not found" if err
			if not err
				db.heroku.destroy_resource resource, (err, resource) =>
					res.send 404, "Cannot deprovision resource." if err
					shared.emit 'heroku_user.unsubscribe', resource
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
			callback_url: req.body.callback_url
		# callback_url unused for the moment

		db.heroku.registerHerokuAppUser data, (err, user) =>
			console.log "err", err
			res.send 404 if err
			if not err
				db.heroku.createDefaultApp user.id, (err, app) =>
					console.log "err", err
					res.send 404 if err
					if not err
						subscribeEvent user, user.current_plan
						# conf_var = 
						# 	name:app.name,
						# 	public_key:app.key
						result = 
							id: 
								user.heroku_id 
							config: 
								OAUTHIO_PUBLIC_KEY: app.key
								# OAUTHIO_APPLICATIONS: JSON.stringify(conf_var)
								# OAUTHIO_URL: user.heroku_url

						stringifyResult = JSON.stringify(result)
						res.setHeader 'Content-Type', 'application/json'
						res.end stringifyResult
						checkProvisionning user, app, (err, res) ->
							if err
								db.heroku.destroy_resource user, (err, resource) =>
									console.log "Cannot deprovision heroku resource: ", err.message if err
									if not err and resource?
										console.log "Cannot access resource on heroku servers: resource deprovisioned."
										shared.emit 'heroku_user.unsubscribe', resource 
					

	checkProvisionning = (user, app, callback) =>
		return callback true if not user? or not user.heroku_id? or not user.mail?
		@myTimeOut = setTimeout ( => 
			clearInterval @myInterval
			return callback true)
			,
			15000
			,
			@myInterval = setInterval ( => 
				db.heroku.getAppInfo user.heroku_id, (err, body) =>
					if not err
						clearTimeout @myTimeOut
						clearInterval @myInterval
						objectBody = JSON.parse(body)
					
						db.apps.addDomain app.key, objectBody.domains[0], (err) ->
							console.log "Cannot add domains to heroku user." if err

							db.heroku.updateConfigVar user, (err, body) =>
								console.log "Unable to update heroku config var." if err
				)
				,
				3000


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

	@on 'user.update_nbapps', (user, nb) =>
		if user? and user.mail?
			db.heroku.updateConfigVar user, (err, body) =>
				console.log "Unable to update heroku config var." if err


	# Heroku will call your service via a POST to /heroku/resources 
	# in order to provision a new resource.
	@server.post new RegExp('/heroku/resources'), restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), checkPlan, provisionResource
	@server.get '/heroku/sso/:id', restify.authorizationParser(), restify.bodyParser({ mapParams: false }), sso_auth, sso_login
	# Heroku will call your service via a PUT to /heroku/resources/:id 
	# in order to change the plan.
	@server.put '/heroku/resources/:id', restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), checkPlan, changePlan
	@server.del '/heroku/resources/:id', restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), deprovisionResource
	@server.post '/heroku/sso/login', restify.authorizationParser(), restify.bodyParser({ mapParams: false }), sso_auth, sso_login
	