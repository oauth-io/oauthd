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
PaymillSubscription = require './paymill_subscription'
PaymillPayment = require './paymill_payment'
PaymillClient = require './paymill_client'

exports.addCart = (data, client, callback) ->

	client_id = client.id
	client_email = client.mail
	plan = data.plan
	prefix_cart = "pm:carts:#{client_id}"
	prefix_plan = "pm:offers:#{plan.name}"

	db.redis.get "#{prefix_plan}:amount", (err, amount) ->
		return callback err if err
		return callback new check.Error "This plan does not exist" if not amount?
		return callback new check.Error "Oh !, Why are you doing this ? :(" if amount != plan.amount

		db.redis.mset [
			"#{prefix_cart}:plan_id", plan.id,
			"#{prefix_cart}:plan_name", plan.name,
			"#{prefix_cart}:unit_price", plan.amount,
			"#{prefix_cart}:quantity", 1,
			"#{prefix_cart}:VAT", "",
			"#{prefix_cart}:VAT_percent", "",
			"#{prefix_cart}:total", "",
			"#{prefix_cart}:email", client_email,
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
		"#{prefix_cart}:email"]
	, (err, replies) ->
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
			email : replies[7]
		}
		return callback null, cart

exports.delCart = check 'int', (client_id, callback) ->

	prefix_cart = "pm:carts:#{client_id}"
	db.redis.del [
		"#{prefix_cart}:plan_id",
		"#{prefix_cart}:plan_name",
		"#{prefix_cart}:unit_price",
		"#{prefix_cart}:quantity",
		"#{prefix_cart}:VAT",
		"#{prefix_cart}:VAT_percent",
		"#{prefix_cart}:total",
		"#{prefix_cart}:email"]
	, (err, replies) ->
		console.log err if err
		return callback err if err
		console.log replies
		return callback null


exports.process = (data, client, callback) ->

	client_id = client.id
	client_email = client.mail

	@pm_client = null
	@pm_subscription = null
	@pm_payment = null

	isNewSubscription = false

	async.series [

		# create Paymill user
		(cb) =>
			db.redis.hget ["#{PaymillBase.subscriptions_root_prefix}", client_id], (err, current_id) =>
				console.log err if err
				return cb err if err

				if not current_id?

					console.log "create user"

					isNewSubscription = true
					@pm_client = new PaymillClient
					@pm_client.user_id = client_id
					@pm_client.email = client_email
					@pm_client.save (err, res) ->
						return cb err if err
						cb()
				else

					console.log "client exists with id #{current_id}"

					isNewSubscription = false
					@pm_client = new PaymillClient current_id
					@pm_client.user_id = client_id
					@pm_client.getCurrentSubscription (err, res) =>
						return cb err if err
						@pm_subscription = res
						cb()

		# create payment
		(cb) =>

			console.log "create payment"
			@pm_payment = new PaymillPayment
			@pm_payment.token = data.token
			@pm_payment.client = @pm_client
			@pm_payment.save (err, res) ->
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

			console.log "subscription..."
			console.log @pm_subscription

			if data.offer # it's a subscription to an offer

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
			#send mail with key
# 			options =
#					templateName:"oauth.html"
#					templatePath:"./app/template/"
# 					to:
# 						email: pm_client.email
# 					from:
# 						name: 'OAuth.io'
# 						email: 'team@oauth.io'
# 					subject: 'OAuth.io - Your payment has been received'
# 					body: "Dear ,\n\n

# Thank you for your recent purchase on Oauth.io.\n\n

# This email message will serve as your receipt.\n
# \n
# You have suscribed to the " + @pm_subscription.offer.name + " offer \n
# with an amount of " + @pm_subscription.offer.amount/100 + "$\n
# your subscription number is : " + @pm_subscription.id + "\n
# your client id is : " + @@pm_client.user_id + "\n
# For help or product support, please contact us at support@oauth.io.\n

# --\n
# OAuth.io Team"
# 			mailer = new Mailer options
# 			mailer.send (err, result) ->
# 				console.log(client_obj.email)
# 				console.log err
# 				return callback err if err
# 				console.log(client_obj.email)
# 				cb()

			console.log "mail..."
			cb()

	], (err, result) =>
		return callback err if err
		return callback null, result

exports.getSubscription = (client_id, callback) ->
	pm_client = new PaymillClient client_id
	pm_client.user_id = client_id
	pm_client.getCurrentSubscription (err, res) =>
		return callback err if err
		return callback null, res.id
		