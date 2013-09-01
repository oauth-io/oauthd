emailer = require 'nodemailer'
config = require '../../lib/config'

class PaymillBase

	@paymill = require('paymill-node')(config.paymill.secret_key)
	@subscriptions_root_prefix = "pm:subscriptions"
	@payments_root_prefix = "pm:payments"
	@carts_root_prefix = "pm:carts"
	@orders_root_prefix = "pm:orders"
	@invoices_root_prefix = "pm:invoices"

	constructor : () ->

exports = module.exports = PaymillBase