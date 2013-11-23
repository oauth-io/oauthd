# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

exports.setup = (callback) ->

	@db.pricing = require './db_pricing'

	@server.get @config.base_api + '/plans', (req, res, next) =>
		@db.pricing.getPublicOffers req.clientId, @server.send(res, next)

	@server.get @config.base_api + '/plans/:name', (req, res, next) =>
		@db.pricing.getOfferByName req.params.name.toLowerCase(), @server.send(res, next)

	@server.del @config.base_api + '/plan/unsubscribe', @auth.needed, (req, res, next) =>
		@db.pricing.unsubscribe req.clientId, @server.send(res, next)

	callback()