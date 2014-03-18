request = require 'request'


exports.setup = (callback) ->

	if not @config.mixpanel?.api_key or not @config.mixpanel.token
		console.log 'Warning: mixpanel plugin is not configured'
		return callback()

	updateUser = (user, data) =>
		mp_data =
			"$token": @config.mixpanel.token
			"$distinct_id": user.id.toString()
			"$set": data
		mp_data = (new Buffer JSON.stringify(mp_data)).toString('base64')
		request {
			url: 'http://api.mixpanel.com/engage/'
			qs: {data:mp_data, verbose:1}
		}, (e, r, body) ->
			console.error "Error while updating contact to mixpanel", e, data, body, r?.statusCode if e or r.statusCode != 200

	sendEvent = (user, name, data) =>
		mp_data =
			event: name,
			properties:
				distinct_id: user.id.toString()
				token: @config.mixpanel.token
		mp_data.properties[k] = v for k, v of data
		mp_data = (new Buffer JSON.stringify(mp_data)).toString('base64')
		request {
			url: 'http://api.mixpanel.com/track/'
			qs: {data:mp_data, verbose:1}
		}, (e, r, body) ->
			console.error "Error while sending event to mixpanel", e, user.id, name, data, body, r?.statusCode if e or r.statusCode != 200

	@on 'user.login', (user) =>
		sendEvent user, 'login'

	@on 'user.pay', (data) =>
		sendEvent data.user.profile, 'user.pay', invoice:data.invoice, customer:data.customer

	@on 'user.pay.failed', (data) =>
		sendEvent data.user.profile, 'user.pay.failed', invoice:data.invoice, customer:data.customer

	@on 'user.subscribe', (data) =>
		updateUser data.user.profile, offer_name: data.subscription.plan.id || "bootstrap"
	@on 'user.unsubscribe', (data) =>
		updateUser data.user.profile, offer_name: 'bootstrap'
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

	callback()