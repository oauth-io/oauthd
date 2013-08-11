# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

exports.setup = (callback) ->

	@db.pricing = require './db_pricing'

	@server.get @config.base + '/api/plans', (req, res, next) =>
		@db.pricing.getPublicOffers @server.send(res, next)

	callback()