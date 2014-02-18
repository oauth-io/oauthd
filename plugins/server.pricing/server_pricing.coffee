# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

exports.setup = (callback) ->

	@db.plans = require './plans'
	@db.pricing = require './db_pricing'

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
			res.send offers:offers, current_plan: plan_id
			return next()

	@server.del @config.base_api + '/plan/unsubscribe', @auth.needed, (req, res, next) =>
		@db.pricing.unsubscribe req.clientId, @server.send(res, next)

	callback()