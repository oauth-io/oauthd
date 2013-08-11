# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#
# Paymill NodeJS docs : https://github.com/komola/paymill-node
#

exports.setup = (callback) ->

	@db.payments = require './db_payments'

	@server.post @config.base + '/api/payment/process', @auth.needed, (req, res, next) =>
		@db.payments.process req.body, req.clientId, @server.send(res, next)

	callback()