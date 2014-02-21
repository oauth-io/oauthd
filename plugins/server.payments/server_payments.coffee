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

	@stripe_hook = (req, res, next) =>
		callback = @server.send(res, next)
		if req.body.type == 'invoice.payment_succeeded'
			@db.payments.payment_succeeded req.body.data.object, callback
		else
			callback()

	@server.post @config.base_api + '/payment/process', @auth.needed, (req, res, next) =>
		@db.payments.process req.body, req.user, @server.send(res, next)

	@server.post '/stripe_hook', (req, res, next) => @stripe_hook req, res, next

	callback()