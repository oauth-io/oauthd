# oauthd
# http://oauth.io
#
# Copyright (c) 2013 Webshell
# For private use only.
#

exports.setup = (callback) ->

	if not @config.stripe?.key || not @config.stripe.secret
		console.log 'Warning: stripe plugin is not configured'
		return callback()

	@db.payments = require './db_payments'
	@db.plans = require './plans'

	@stripe_hook = (req, res, next) =>
		callback = @server.send(res, next)
		return callback() if not @db.payments.hooks[req.body.type]
		@db.payments.hooks[req.body.type] req.body.data.object, callback

	@server.post '/stripe_hook', (req, res, next) => @stripe_hook req, res, next

	@server.post @config.base_api + '/payment/subscribe', @auth.needed, (req, res, next) =>
		@db.payments.subscribe req.body, req.user, @server.send(res, next)

	@server.del @config.base_api + '/payment/unsubscribe', @auth.needed, (req, res, next) =>
		@db.payments.unsubscribe req.user, @server.send(res, next)

	@server.post @config.base_api + '/payment/coupon', @auth.needed, (req, res, next) =>
		@db.payments.getCoupon req.body, @server.send(res, next)

	@server.get @config.base_api + '/plans', @auth.optional, (req, res, next) =>
		offers = []
		for id,plan of @db.plans
			if id.split('_').length == 1
				offers.push plan

		if not req.user
			res.send offers:offers, current_plan: null
			return next()

		@db.redis.get "u:#{req.user.id}:current_plan", (err, plan_id) ->
			return next err if err
			plan_id = plan_id.split('_')[0] if plan_id
			res.send offers: offers, current_plan: plan_id
			return next()

	callback()