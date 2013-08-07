
exports.setup = (callback) ->

	@db.payments = require './db_payments'

	@server.get @config.base + '/api/payment/process', (req, res, next) =>
		console.log "payment request..."	
		@db.payments.process req.data, 1, @server.send(res, next)		

	callback()