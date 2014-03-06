# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# Licensed under the MIT license.

'use strict'

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
			
			heroku_url = 'https://oauth.io/auth/heroku/' + data.heroku_id.split("@")[0]
			
			arr = ['mset', prefix+'mail', "",
					prefix+'key', key,
					prefix+'validated', 1,
					prefix+'date_inscr', date_inscr,
					prefix+'date_validate', (new Date).getTime(),
					prefix+'heroku_id', data.heroku_id,
					prefix+'heroku_url', heroku_url,
					prefix+'plan', data.plan ]

			db.redis.multi([
					arr,
					[ 'hset', 'u:heroku_url', heroku_url, val ]
				]).exec (err, res) ->
					return callback err if err
					user = id:val, heroku_id:data.heroku_id, heroku_url:heroku_url, plan:data.plan, date_inscr:date_inscr, key:key
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

	# * Provisioning
	# A private resource is created for each app that adds your add-on.
	# Any provisioned resource should be referenced by a unique URL, 
	# which is how the customer’s app consumes the resource.
	# 
	###### RETURN a json containing
	# - the ID
	# - a config var hash containing a URL to consume the service
	provisionResource = (req, res, next) =>
		console.log "heroku resources post"
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
			console.log "result", result
			res.send result

	# Heroku will call your service via a POST to /heroku/resources 
	# in order to provision a new resource.
	@server.post new RegExp('/heroku/resources'), restify.authorizationParser(), basic_auth, restify.bodyParser({ mapParams: false }), provisionResource