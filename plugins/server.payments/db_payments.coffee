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

			db.redis.hget "#{PaymillBase.payments_root_prefix}:#{client_id}", "current_payment", (err, res) =>
				return cb err if err

				if not res?
					console.log "create payment"
					@pm_payment = new PaymillPayment
					@pm_payment.token = data.token
					@pm_payment.client = @pm_client
					@pm_payment.save (err, res) ->
						return cb err if err
						cb()
				else
					console.log "payment exists"
					@pm_payment = new PaymillPayment res
					cb()

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
# For help or product support, please contact us at team@oauth.io.\n

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

	], (err, result) ->
		return callback err if err
		return callback null, result
