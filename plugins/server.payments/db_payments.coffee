# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#
# Paymill NodeJS docs : https://github.com/komola/paymill-node
#

async = require 'async'
restify = require 'restify'
Mailer = require '../../lib/mailer'
{ db, check, config } = shared = require '../shared'
PaymillBase = require './paymill_base'
DbUser = require '../server.users/db_users'
Payment = require '../server.payments/db_payments'

exports.paddingLeft = (padding, value) ->
	zeroes = "0"
	zeroes += "0" for i in [1..padding]

	(zeroes + value).slice(padding * -1)

exports.addInvoice = (cart, num_order, subscription, callback) ->

	return callback new check.Error "Cannot create invoice, please contact support@oauth.io" if not cart? or not num_order?

	db.redis.incr "#{PaymillBase.invoices_root_prefix}:i", (err, num) ->
		return callback err if err

		date = new Date
		day = exports.paddingLeft(2, date.getDate())
		month = exports.paddingLeft(2, date.getMonth() + 1)
		year = date.getFullYear()

		num_invoice = exports.paddingLeft(7, num)
		num_invoice = "I#{day}#{month}#{year}-#{num_invoice}"

		db.redis.hset "#{PaymillBase.invoices_root_prefix}:num_invoices", num_invoice, num_order, (err, res) ->
			return callback err if err

			db.redis.mset [
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:num_invoice", num_invoice,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:num_order", num_order,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:date_invoice", Math.round((new Date()).getTime() / 1000),
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:plan_id", cart.plan_id,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:plan_name", cart.plan_name,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:unit_price", cart.unit_price,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:quantity", cart.quantity,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:VAT", cart.VAT,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:VAT_percent", cart.VAT_percent,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:total", cart.total,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:email", cart.email,
				"#{PaymillBase.invoices_root_prefix}:#{cart.client_id}:#{num_invoice}:refund_total", cart.refund_total,

				"#{PaymillBase.subscriptions_root_prefix}:#{cart.client_id}:#{subscription.data.id}:num_order", num_order,
				"#{PaymillBase.subscriptions_root_prefix}:#{cart.client_id}:#{subscription.data.id}:num_invoice", num_invoice
			], (err) ->
				return callback err if err
				return callback null


exports.getInvoice = (client_id, subscription_id, callback) ->
	db.redis.get "#{PaymillBase.subscriptions_root_prefix}:#{client_id}:#{subscription_id}:num_invoice" , (err, res) ->
		return callback err if err
		prefix = "#{PaymillBase.invoices_root_prefix}:#{client_id}:#{res}:"
		db.redis.mget [ prefix + 'num_invoice',
			prefix + 'num_order',
			prefix + 'date_invoice',
			prefix + 'plan_id',
			prefix + 'plan_name',
			prefix + 'unit_price',
			prefix + 'quantity',
			prefix + 'VAT',
			prefix + 'VAT_percent',
			prefix + 'total',
			prefix + 'email',
		 	prefix + 'refund_total']
		, (err, replies) ->
			return callback err if err
			date = new Date(replies[2] * 1000)
			months = new Array('January', 'February', 'March', 'April', 'May', 'June', 'Jully', 'August', 'September', 'October', 'November', 'December');
			invoice =
			{
				num_invoice:replies[0],
				num_order:replies[1],
				date_invoice: (months[date.getMonth()]) + " " + date.getDate() + ", " + date.getFullYear(),
				plan_id: replies[3],
				plan_name: replies[4],
				unit_price: replies[5],
				quantity: replies[6],
				VAT: replies[7],
				VAT_percent: replies[8],
				total: replies[9],
				email: replies[10],
				refund_total: replies[11]
			}
			return callback null, invoice

exports.addOrder = (client_id, subscription, callback) ->

	return callback new check.Error "Cannot create order, please contact support@oauth.io" if not client_id?

	exports.getCart client_id, (err, cart) ->

		return callback err if err

		db.redis.incr "#{PaymillBase.orders_root_prefix}:i", (err, num) ->
			return callback err if err

			date = new Date
			day = exports.paddingLeft(2, date.getDate())
			month = exports.paddingLeft(2, date.getMonth() + 1)
			year = date.getFullYear()

			num_order = exports.paddingLeft(7, num)
			num_order = "O#{day}#{month}#{year}-#{num_order}"

			db.redis.hset "#{PaymillBase.orders_root_prefix}:num_orders", num_order, cart.client_id, (err, res) ->
				return callback err if err

				db.redis.mset [
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:num_order", num_order,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:date_order", Math.round((new Date()).getTime() / 1000),
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:plan_id", cart.plan_id,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:plan_name", cart.plan_name,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:unit_price", cart.unit_price,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:quantity", cart.quantity,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:VAT", cart.VAT,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:VAT_percent", cart.VAT_percent,
					"#{PaymillBase.orders_root_prefix}:#{cart.client_id}:#{num_order}:refund_total", cart.refund_total,
				], (err) =>
					return callback err if err

					exports.addInvoice cart, num_order, subscription, (err, res) ->
						return callback err if err
						return callback null



exports.addCart = (data, client, callback) ->

	client_id = client.id
	client_email = client.mail
	plan = data.plan
	prefix_cart = "pm:carts:#{client_id}"

	prefix_plan = "pm:offers:#{plan.name}"
	db.redis.get "#{prefix_plan}:amount", (err, amount) ->
		return callback err if err
		return callback new check.Error "This plan does not exist" if not amount?
		return callback new check.Error "Oh !, Bad request !!! :(" if amount != plan.amount

		db.redis.hget "#{PaymillBase.subscriptions_root_prefix}:#{client_id}", "current_subscription", (err, current_subscription) ->

			if current_subscription?

				db.redis.hget "#{PaymillBase.subscriptions_root_prefix}", client_id, (err, paymill_client_id) ->

					PaymillBase.paymill.clients.details paymill_client_id, (err, client) ->

						old_subscription = client.data.subscription[client.data.subscription.length - 1]

						PaymillBase.paymill.transactions.list description:old_subscription.id, (err, transaction) =>

							oldSubDate1 = new Date(transaction.data[transaction.data.length - 1].created_at * 1000)
							oldSubDate2 = new Date(old_subscription.next_capture_at * 1000)
							newSubDate = new Date()
							nbDaysDiff = Math.floor( ((newSubDate - oldSubDate1) / (1000 * 60 * 60 * 24)) * 100) / 100

							nbDaysDiff = 1 if nbDaysDiff >= 0.06 and nbDaysDiff <= 0.99

							oldNextCapture = new Date(oldSubDate2.getYear(), oldSubDate2.getMonth(), oldSubDate2.getDate())
							oldLastCapture = new Date(oldSubDate1.getYear(), oldSubDate1.getMonth(), oldSubDate1.getDate())

							nbDays = ((oldNextCapture - oldLastCapture) / (1000 * 60 * 60 * 24))

							last_price = old_subscription.offer.amount / 100
							refunded = Math.floor( ((nbDaysDiff / nbDays) * last_price) * 100) / 100
							refund_total = Math.floor((last_price - refunded) * 100) / 100

							db.redis.mset [
								"#{prefix_cart}:plan_id", plan.id,
								"#{prefix_cart}:plan_name", plan.name,
								"#{prefix_cart}:unit_price", plan.amount,
								"#{prefix_cart}:quantity", 1,
								"#{prefix_cart}:VAT", "",
								"#{prefix_cart}:VAT_percent", "",
								"#{prefix_cart}:total", "",
								"#{prefix_cart}:email", client_email,
								"#{prefix_cart}:client_id", client_id,
								"#{prefix_cart}:refund_total", refund_total
							], (err) ->
								return callback err if err
								return callback null
			else
				db.redis.mset [
					"#{prefix_cart}:plan_id", plan.id,
					"#{prefix_cart}:plan_name", plan.name,
					"#{prefix_cart}:unit_price", plan.amount,
					"#{prefix_cart}:quantity", 1,
					"#{prefix_cart}:VAT", "",
					"#{prefix_cart}:VAT_percent", "",
					"#{prefix_cart}:total", "",
					"#{prefix_cart}:email", client_email,
					"#{prefix_cart}:client_id", client_id,
				], (err) ->
					return callback err if err
					return callback null


exports.getCart = check 'int', (client_id, callback) ->

	prefix_cart = "pm:carts:#{client_id}"
	db.redis.mget [
		"#{prefix_cart}:plan_id",
		"#{prefix_cart}:plan_name",
		"#{prefix_cart}:unit_price",
		"#{prefix_cart}:quantity",
		"#{prefix_cart}:VAT",
		"#{prefix_cart}:VAT_percent",
		"#{prefix_cart}:total",
		"#{prefix_cart}:email",
		"#{prefix_cart}:client_id",
		"#{prefix_cart}:refund_total",
	], (err, replies) ->
		return callback err if err
		cart =
		{
			plan_id : replies[0],
			plan_name : replies[1],
			unit_price : (replies[2] / 100).toFixed(2),
			quantity : parseInt(replies[3]),
			VAT : replies[4],
			VAT_percent: replies[5],
			total: replies[6],
			email : replies[7],
			client_id: replies[8],
			refund_total: replies[9]
		}
		return callback null, cart

exports.delCart = check 'int', (client_id, callback) ->

	return callback new check.Error "Cannot delete cart" if not client_id?

	prefix_cart = "pm:carts:#{client_id}"
	db.redis.del [
		"#{prefix_cart}:plan_id",
		"#{prefix_cart}:plan_name",
		"#{prefix_cart}:unit_price",
		"#{prefix_cart}:quantity",
		"#{prefix_cart}:VAT",
		"#{prefix_cart}:VAT_percent",
		"#{prefix_cart}:total",
		"#{prefix_cart}:email"
		"#{prefix_cart}:client_id",
		"#{prefix_cart}:refund_total"
	], (err, replies) ->
		return callback err if err
		return callback null


exports.process = (data, client, callback) ->

	client_id = client.id
	client_email = client.mail

	@pm_client = null
	@pm_subscription = null
	@pm_payment = null

	isNewSubscription = false

	console.log "process..."
	async.series [

		# create Paymill user
		(cb) =>
			db.redis.hget ["#{PaymillBase.subscriptions_root_prefix}", client_id], (err, current_id) =>
				console.error err if err
				return cb err if err

				PaymillClient = require './paymill_client'

				console.log "creating user..."
				if not current_id?
					console.log " new user..."
					isNewSubscription = true
					@pm_client = new PaymillClient
					@pm_client.user_id = client_id
					@pm_client.email = client_email
					@pm_client.save (err, res) ->
						return cb err if err
						cb()
				else
					console.log " existing user..."
					isNewSubscription = false
					@pm_client = new PaymillClient current_id
					@pm_client.user_id = client_id
					@pm_client.email = client_email
					@pm_client.getCurrentSubscription (err, res) =>
						return cb err if err
						@pm_subscription = res
						cb()

		# create payment
		(cb) =>
			console.log "creating payment..."
			PaymillPayment = require './paymill_payment'
			@pm_payment = new PaymillPayment
			@pm_payment.token = data.token
			@pm_payment.client = @pm_client
			@pm_payment.save (err, res) ->
				console.log err, "creating payment" if err
				return cb err if err
				cb()

			# db.redis.hget "#{PaymillBase.payments_root_prefix}:#{client_id}", "current_payment", (err, res) =>
			# 	return cb err if err

			# 	if not res?
			# 		console.log "create payment"
			# 		@pm_payment = new PaymillPayment
			# 		@pm_payment.token = data.token
			# 		@pm_payment.client = @pm_client
			# 		@pm_payment.save (err, res) ->
			# 			return cb err if err
			# 			cb()
			# 	else
			# 		console.log "payment exists"
			# 		@pm_payment = new PaymillPayment res
			# 		cb()

		# create subscription
		(cb) =>

			if data.offer # it's a subscription to an offer
				console.log "subscription ok..."
				PaymillSubscription = require './paymill_subscription'
				@pm_subscription = new PaymillSubscription if not @pm_subscription?
				@pm_subscription.client = @pm_client
				@pm_subscription.offer = { id : data.offer }
				@pm_subscription.payment = @pm_payment
				@pm_subscription.save (err, res) ->
					return cb err if err
					cb null, res

			else

				cb new check.Error "Missing offer !"

		# notify user
		(cb) =>


			# set invoice to data for the template
			name_template = "mail_payment"

			exports.getSubscription @pm_client.user_id, (error, subscription_id) =>
				return error if error
				DbUser.get @pm_client.user_id, (e, user) =>
					return e if e
					exports.getInvoice @pm_client.user_id, subscription_id , (err, invoice) =>
						return err if err

						#send mail with key
						if invoice.VAT_percent != "0"
							name_template += "_fr"
						options =
							templateName:name_template
							templatePath:"./app/template/"
							to:
								email: @pm_client.email
							from:
								name: 'OAuth.io'
								email: 'team@oauth.io'
							subject: 'OAuth.io - Your payment has been received'

						months = new Array('January', 'February', 'March', 'April', 'May', 'June', 'Jully', 'August', 'September', 'October', 'November', 'December');
						date = new Date()
						data =
							date:  (months[date.getMonth()]) + " " + date.getDate() + ", " + date.getFullYear()
							user: user
							invoice: invoice

						mailer = new Mailer options, data
						mailer.send (err, result) ->
							return callback err if err
							cb()

						shared.emit 'user.pay', user:user, invoice:invoice


	], (err, result) =>
		return callback err if err
		return callback null, result

exports.getSubscription = (client_id, callback) ->
	PaymillClient = require './paymill_client'

	pm_client = new PaymillClient client_id
	pm_client.user_id = client_id
	pm_client.getCurrentSubscription (err, res) =>
		return callback err if err
		return callback null, null  if not res?
		return callback null, res.id
