exports.setup = (callback) ->

	@db.payments = require './db_payments'

	@server.post @config.base + '/api/payment/process', (req, res, next) =>
		@db.payments.process req.body, req.clientId, @server.send(res, next)

	callback()