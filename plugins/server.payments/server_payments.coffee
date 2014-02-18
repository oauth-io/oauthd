# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#
# Paymill NodeJS docs : https://github.com/komola/paymill-node
#

exports.setup = (callback) ->

	if not @config.stripe?.key || not @config.stripe.secret
		console.log 'Warning: stripe plugin is not configured'
		return callback()

	@db.payments = require './db_payments'

	@server.post @config.base_api + '/payment/process', @auth.needed, (req, res, next) =>
		@db.payments.process req.body, req.user, @server.send(res, next)

	callback()