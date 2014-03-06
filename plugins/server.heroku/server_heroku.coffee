# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# Licensed under the MIT license.

'use strict'

{config,check,db} = shared = require '../shared'

exports.raw = ->

	registerHerokuAppUser = (callback) ->
		date_inscr = (new Date).getTime()

		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			key = db.generateUid()
			heroku_id = 'heroku_app' + val
			
			dynsalt = Math.floor(Math.random() * 9999999)
			pass = db.generateHash heroku_id + dynsalt
			
			heroku_url = 'https://oauth.io/auth/heroku/' + pass
			
			arr = ['mset', prefix+'mail', "",
					prefix+'key', key,
					prefix+'validated', 1,
					prefix+'pass', pass,
					prefix+'date_inscr', date_inscr,
					prefix+'date_validate', (new Date).getTime(),
					prefix+'heroku_id', heroku_id,
					prefix+'heroku_url', heroku_id ]

			db.redis.multi([
					arr,
					[ 'hset', 'u:heroku_url', heroku_url, val ]
				]).exec (err, res) ->
					return callback err if err
					user = id:val, heroku_id:heroku_id, heroku_url:heroku_url, date_inscr:date_inscr, key:key
					# shared.emit 'user.register', user
					return callback null, user

	# * Provisioning
	# A private resource is created for each app that adds your add-on.
	# Any provisioned resource should be referenced by a unique URL, 
	# which is how the customer’s app consumes the resource.
	# RETURN a json containing
	# - the ID
	# - a config var hash containing a URL to consume the service
	provisionResource = (req, res, next) =>
		console.log "heroku resources post"
		req.params heroku_user
		
		registerHerokuAppUser (err, user) =>
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
	@server.post new RegExp('/heroku/resources'), provisionResource