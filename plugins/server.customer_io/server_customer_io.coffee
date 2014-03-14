request = require 'request'
async = require 'async'

exports.setup = (callback) ->

	if not @config.customer_io?.site_id or not @config.customer_io.api_key
		console.log 'Warning: customer.io plugin is not configured'
		return callback()

	customerio = request.defaults
		auth:
			user: @config.customer_io.site_id
			pass: @config.customer_io.api_key

	timestamp = (v) -> Math.floor(v/1000)

	updateUser = (user, data) =>
		mkData = (cb) =>
			cpydata = {}
			cpydata[k] = v for k,v of data
			if user.mail
				cpydata.email = user.mail
				return cb null, cpydata
			@db.redis.get 'u:' + user.id + ':mail', (e,mail) ->
				return cb e if e
				cpydata.email = mail
				cb null, cpydata
		mkData (e,data) =>
			return if e
			customerio.put {
				url: 'https://track.customer.io/api/v1/customers/' + user.id
				json: data
			}, (e, r, body) ->
				console.error "Error while updating contact to customer.io", e, data, body, r.statusCode if e or r.statusCode != 200

	sendEvent = (user, name, data) =>
		reqData = name: name
		reqData.data = data if data
		customerio.post {
			url: 'https://track.customer.io/api/v1/customers/' + user.id + '/events'
			json: reqData
		}, (e, r, body) ->
			console.error "Error while sending event to customer.io", e, user.id, name, data, body, r.statusCode if e or r.statusCode != 200

	@on 'cohort.inscr', (user, now) =>
		updateUser user, date_inscr:timestamp(now), created_at:timestamp(now), key:user.key
	@on 'cohort.validate', (user, now) =>
		updateUser user, date_validate:timestamp(now)
	@on 'cohort.activation', (user, now) =>
		updateUser user, date_activation:timestamp(now)
	@on 'cohort.development', (user, now) =>
		updateUser user, date_development:timestamp(now)
	@on 'cohort.production', (user, now) =>
		updateUser user, date_production:timestamp(now)
	@on 'cohort.consumer', (user, now) =>
		updateUser user, date_consumer:timestamp(now)
	@on 'cohort.ready', (user, now) =>
		updateUser user, date_ready:timestamp(now)

	@on 'user.login', (user) =>
		sendEvent user, 'login'

	@on 'user.pay', (data) =>
		sendEvent data.user.profile, 'user.pay', invoice:data.invoice, customer:data.customer

	@on 'user.pay.failed', (data) =>
		sendEvent data.user.profile, 'user.pay.failed', invoice:data.invoice, customer:data.customer

	@on 'user.subscribe', (data, offer) =>
		updateUser data.user.profile, offer_name: offer || "free"
	@on 'user.unsubscribe', (data) =>
		updateUser data.user.profile, offer_name: 'free'
		sendEvent data.user.profile, 'unsubscribe'

	@on 'heroku_user.subscribe', (heroku_user, offer) =>
		sendEvent heroku_user, 'heroku_user_subscribe'
	@on 'heroku_user.unsubscribe', (heroku_user) =>
		sendEvent heroku_user, 'heroku_user_unsubscribe'

	@on 'app.create', (req, app) =>
		sendEvent req.user, 'app.create', app
	@on 'app.remove', (req, app) =>
		sendEvent req.user, 'app.remove', app
	@on 'user.update_nbapps', (user, nb) =>
		updateUser user, nb_apps: nb
	@on 'user.update_nbproviders', (user, nb) =>
		updateUser user, nb_providers: nb
	@on 'user.update_nbauth', (user, month, nb) =>
		userInfo = {}
		userInfo['nb_auth_' + month] = nb
		updateUser user, userInfo
	@on 'user.update_nbuid', (user, month, nb) =>
		userInfo = {}
		userInfo['nb_uid_' + month] = nb
		updateUser user, userInfo
	@on 'user.update_nbmid', (user, month, nb) =>
		userInfo = {}
		userInfo['nb_mid_' + month] = nb
		updateUser user, userInfo

	@on 'app.remkeyset', (data) =>
		@db.apps.getOwner data.app, (e, user) =>
			return if e
			sendEvent user, 'app.remkeyset', data

	@on 'app.addkeyset', (data) =>
		@db.apps.getOwner data.app, (e, user) =>
			return if e
			sendEvent user, 'app.addkeyset', data
	@on 'app.updatekeyset', (data) =>
		@db.apps.getOwner data.app, (e, user) =>
			return if e
			sendEvent user, 'app.updatekeyset', data

	@on 'request', (data) =>
		@db.apps.getOwner data.key, (e, user) =>
			return if e
			sendEvent user, 'app.request', data

	@on 'connect.auth', (data) =>
		@db.apps.getOwner data.key, (e, user) =>
			return if e
			sendEvent user, 'connect.auth', provider:data.provider, key:data.key

	@on 'connect.auth.new_uid', (data) =>
		@db.apps.getOwner data.key, (e, user) =>
			return if e
			sendEvent user, 'connect.auth.new_uid', provider:data.provider, key:data.key

	@on 'connect.callback', (data) =>
		@db.apps.getOwner data.key, (e, user) =>
			return if e
			eventData = provider:data.provider, key:data.key, origin:data.origin, status:data.status
			for apiname, apivalue of data.parameters
				eventData['_' + apiname] = apivalue if Array.isArray(apivalue)
			sendEvent user, 'connect.callback', eventData

	@on 'connect.callback.new_uid', (data) =>
		@db.apps.getOwner data.key, (e, user) =>
			return if e
			eventData = provider:data.provider, key:data.key, origin:data.origin, status:data.status
			for apiname, apivalue of data.parameters
				eventData['_' + apiname] = apivalue if Array.isArray(apivalue)
			sendEvent user, 'connect.callback.new_uid', eventData

	@server.post @config.base_api + '/adm/customerio/update', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			for mail,iduser of users
				pfx = 'u:' + iduser + ':'
				cmds.push ['mget',
					pfx+'date_inscr'
					pfx+'date_validate'
					pfx+'date_activation'
					pfx+'date_development'
					pfx+'date_production'
					pfx+'date_consumer'
					pfx+'key'
					pfx+'validated'
					pfx+'name',
					pfx+'current_plan'
				]
				cmds.push ['scard', pfx+'apps']
				cmds.push ['scard', pfx+'providers']
			console.log '[ADMIN] start customer.io update'
			@db.redis.multi(cmds).exec (err, r) =>
				console.log '[ADMIN] error with big multi', err if err
				return if err
				i = 0
				tasks = []
				for mail,iduser of users
					do (i,mail,iduser) ->
						tasks.push (callback) ->
							user = id:iduser, mail:mail
							profile = r[i*3]
							updateInfo =
								created_at:timestamp(profile[0])
								date_inscr:timestamp(profile[0])
								key:profile[6]
								validated:profile[7]-0
								nb_apps:r[i*3+1]
								nb_providers:r[i*3+2]
							updateInfo.date_validate = timestamp(profile[1]) if profile[1]
							updateInfo.date_activation = timestamp(profile[2]) if profile[2]
							updateInfo.date_development = timestamp(profile[3]) if profile[3]
							updateInfo.date_production = timestamp(profile[4]) if profile[4]
							updateInfo.date_consumer = timestamp(profile[5]) if profile[5]
							updateInfo.name = profile[8] if profile[8]
							updateInfo.offer_name = profile[9] if profile[9]

							updateUser user, updateInfo
							callback()
					i++
				async.parallel tasks, (e,r) ->
					console.log '[ADMIN] finish customer.io (there still may be http requests in pool)'
			res.send @check.nullv
			next()

	callback()