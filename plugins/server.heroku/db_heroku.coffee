# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

async = require 'async'
request = require 'request'

{config,check,db} = shared = require '../shared'

# Use this call to get a list of apps that have installed your add-on.
# Request       : GET https://username:password@api.heroku.com/vendor/apps
exports.getAllApps = (callback) ->
	options =
		uri: "https://" + config.heroku.heroku_user + ":" + config.heroku.heroku_password + "@api.heroku.com/vendor/apps",
		method: 'GET'

	request options, (err, response, body) ->
		return callback err if err
		if response.statusCode != 200
			return callback true
		return callback null, body

# Use this call to get the full set of details on any of your add-on instances. 
# This endpoint will only return a 200 response after provisioning has completed. 
# Trying to access App Info during a provisioning request will return a 404 response.
# Request       : GET https://username:password@api.heroku.com/vendor/apps/:heroku_id
exports.getAppInfo = (heroku_id, callback) ->
	options =
		uri: "https://" + config.heroku.heroku_user + ":" + config.heroku.heroku_password + "@api.heroku.com/vendor/apps/" + heroku_id,
		method: 'GET'

	request options, (err, response, body) ->
		return callback err if err
		if response.statusCode != 200
			return callback true
		return callback null, body


# Use this call to update config vars that were previously set for an application during provisioning.
# You can only update config vars that have been declared in your addon-manifest.json.
# Request        : PUT https://username:password@api.heroku.com/vendor/apps/:heroku_id
# Request Body   : { "config": {"MYADDON_URL": "http://myaddon.com/ABC123"}}
# Response       : 200 OK
exports.updateConfigVar = (user, callback) =>
	return callback true if not user? or not user.mail? or not user.id?
	db.heroku.get_resource_by_id user.mail, (err, resource) =>
		if not err
			db.users.getAppsObject user.id, (err, apps) ->
				conf_var = []
				for app in apps
					var_domains = JSON.stringify(app.domains)
					var_app	=
						name:app.name,
						public_key:app.key,
						domains:app.domains
					conf_var.push var_app
				reqbody =  
					config: 
						OAUTHIO_APPLICATIONS:JSON.stringify(conf_var)
				options =
					uri: "https://" + config.heroku.heroku_user + ":" + config.heroku.heroku_password + "@api.heroku.com/vendor/apps/" + resource.heroku_id,
					method: 'PUT',
					body: JSON.stringify(reqbody),
					headers: {'Content-Type': 'application/json'}
				request options, (err, response, body) ->
					return callback err if err
					if response.statusCode != 200
						return callback true
					return callback null, body


exports.registerHerokuAppUser = (data, callback) ->
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


exports.get_resource_by_id = (hid, callback) ->
	db.redis.hget 'u:heroku_id', hid, (err, idresource) ->
		return callback true if err or not idresource?
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
			return callback null, resource


exports.destroy_resource = (resource, callback) ->
	idresource = resource.id
	return callback true if not idresource?
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
						prefix + 'apps',
						prefix+'name', 
						prefix+'pass', 
						prefix+'salt',
						prefix+'date_ready', 
						prefix+'platform', 
						prefix+'platform_admin' ]
				]).exec (err, replies) ->
					return callback err if err
					shared.emit 'user.remove', mail:resource.mail
					shared.emit 'heroku_user.remove', mail:resource.mail
					return callback null, resource



exports.createDefaultApp = (userid, callback) =>
	data =
		domains:["localhost"]
		name:"Heroku default app"
	user =
		id:userid
	db.apps.create data, user, (err, app) ->
		return callback err if err or not app?
		shared.emit 'app.create', user, app
		return callback null, app



