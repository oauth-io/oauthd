# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

plans = require './plans'

exports.setup = (callback) ->

	@db.pricing = require './db_pricing'

	@server.get @config.base_api + '/plans', (req, res, next) =>
		offers = []
		for id,plan of plans
			if id.split('_').length == 1
				plan.apps = "Unlimited" if plan.apps == Infinity
				offers.push plan

		res.send offers:offers, current_offer: 'bootstrap'

	@server.del @config.base_api + '/plan/unsubscribe', @auth.needed, (req, res, next) =>
		@db.pricing.unsubscribe req.clientId, @server.send(res, next)

	callback()