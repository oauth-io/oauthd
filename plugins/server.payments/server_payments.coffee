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

	@server.post @config.base + '/api/payment/cart/new', @auth.needed, (req, res, next) =>
		@db.payments.addCart req.body, req.clientId, @server.send(res, next)

	@server.get @config.base + '/api/payment/cart/get', @auth.needed, (req, res, next) =>
		@db.payments.getCart req.clientId.id, @server.send(res, next)

	callback()