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
paymill = require('paymill-node')(config.paymill.secret_key)

exports.process = (data, client, callback) ->

	client_id = client.id
	client_email = client.mail
	isNewSubscription = false
	current_offer_key = null

	## NEW SUBSCRIPTION ##
	client_obj =
		email : ''

	payment_obj =
		token: ''
		client: ''

	subscription_obj =
		client: ''
		offer: ''
		payment: ''

	## CURRENT SUBSCRIPTION ##
	current_subscription =
		id: ''
		next_capture: ''

	subscriptions_root_prefix = "pm:subscriptions"
	payments_root_prefix = "pm:payments"

	async.series [

		# create Paymill user
		(cb) ->
			console.log "creating Paymill user..."
			db.redis.hget ["#{subscriptions_root_prefix}", client_id], (err, current_id) ->
				return cb err if err

				client_obj.id = current_id if current_id?
				client_obj.email = client_email

				if not current_id?

					console.log "\t new user detected"

					isNewSubscription = true

					# create Paymill user
					paymill.clients.create client_obj, (err, client) ->
						return cb err if err

						id = client.data.id # Paymill id
						client_obj.id = id

						# Paymill user id to Redis
						db.redis.hset "#{subscriptions_root_prefix}", client_id, id, (err, res) ->
							return cb err if err
							console.log "\t [OK]"
							cb null, client
				else
					console.log "\t user exists with id #{current_id}"
					db.redis.hget "#{subscriptions_root_prefix}:#{client_id}", (err, res) ->
						return cb err if err

						paymill.subscriptions.details res, (err, res) ->
							return cb err if err
							current_subscription.id = res.id
							current_subscription.next_capture = res.next_capture_at
							cb()

		# create payment
		(cb) ->

			payment_obj.token = data.token
			payment_obj.client = client_obj.id

			db.redis.hget "#{payments_root_prefix}:#{client_id}", "current_payment", (err, res) ->
				return cb err if err
				console.log res
				if res?
					console.log "retrieving current credit card informations..."
					payment_obj.id = res
					cb()
				else
					console.log "creating Paymill payment...(card info)"

					paymill.payments.create payment_obj, (err, payment) ->
						return cb err if err

						payment_obj.id = payment.data.id

						console.log "\t creating on redis..."

						# Payment : credit card infos...
						payment_prefix = "#{payments_root_prefix}:#{client_id}:#{payment.data.id}"

						db.redis.multi([

							[ "hset", "#{payments_root_prefix}:#{client_id}", "current_payment", payment_obj.id ],

							[ "mset", "#{payment_prefix}:client", payment.data.client,
							"#{payment_prefix}:card_type", payment.data.card_type,
							"#{payment_prefix}:country", payment.data.country,
							"#{payment_prefix}:expire_month", payment.data.expire_month,
							"#{payment_prefix}:expire_year", payment.data.expire_year,
							"#{payment_prefix}:card_holder", payment.data.card_holder,
							"#{payment_prefix}:last4", payment.data.last4,
							"#{payment_prefix}:created_at", payment.data.created_at ]

						]).exec (err) ->
							return cb err if err
							cb()

		# create subscription
		(cb) ->

			if data.offer # it's a subscription to an offer

				subscription_obj.client = client_obj.id
				subscription_obj.offer = data.offer
				subscription_obj.payment = payment_obj.id

				if isNewSubscription
					console.log "creating Paymill subscription..."

					paymill.subscriptions.create subscription_obj, (err, subscription) ->
						console.log err
						return cb err if err

						console.log "\t subscription created on Paymill"
						console.log "\t creating on redis..."

						subscription_prefix = "#{subscriptions_root_prefix}:#{client_id}:#{subscription.data.id}"

						db.redis.multi([

							[ "hset", "#{subscriptions_root_prefix}:#{client_id}:history", subscription.data.offer.id, subscription.data.created_at],

							[ "hset", "#{subscriptions_root_prefix}:#{client_id}", "current_subscription", subscription.data.id ],

							[ "hset", "#{subscriptions_root_prefix}:#{client_id}", "current_offer", subscription_obj.offer ],

							[ "mset", "#{subscription_prefix}:id", subscription.data.id,
								"#{subscription_prefix}:offer", subscription.data.offer.id,
								"#{subscription_prefix}:next_capture_at", subscription.data.next_capture_at,
								"#{subscription_prefix}:created_at", subscription.data.created_at,
								"#{subscription_prefix}:updated_at", subscription.data.updated_at,
								"#{subscription_prefix}:canceled_at", subscription.data.canceled_at,
								"#{subscription_prefix}:payment", subscription.data.payment.id,
								"#{subscription_prefix}:client", subscription.data.client.id,
								"#{subscription_prefix}:notified", false ]

						]).exec (err) ->
							return cb err if err
							console.log "\t subscription created on Redis"
							cb null, subscription

				else

					console.log "update Paymill subscription..."

					db.redis.multi([

						[ "hget", "#{subscriptions_root_prefix}:#{client_id}", "current_subscription"],
						[ "hget", "#{subscriptions_root_prefix}:#{client_id}", "current_offer" ]

					]).exec (err, res) ->
						console.log err
						return cb err if err
						return cb new check.Error "An error occured, please contact support@oauth.io" if not res?
						return cb new check.Error "You can not subscribe to the same plan" if res[1] == subscription_obj.offer

						update_subscription_obj =
							cancel_at_period_end : true
							offer : subscription_obj.offer

						paymill.subscriptions.remove res[0], (err, subscription_updated) ->
							console.log err
							return cb err if err

							subscription_obj.start_at = current_subscription.next_capture

							paymill.subscriptions.create subscription_obj, (err, subscription) ->
								console.log err
								return cb err if err

								subscription_prefix = "#{subscriptions_root_prefix}:#{client_id}:#{subscription.data.id}"

								db.redis.multi([

									[ "hset", "#{subscriptions_root_prefix}:#{client_id}:history", subscription.data.offer.id, subscription.data.created_at],

									[ "hset", "#{subscriptions_root_prefix}:#{client_id}", "current_subscription", subscription.data.id ],

									[ "hset", "#{subscriptions_root_prefix}:#{client_id}", "current_offer", subscription_obj.offer ],

									[ "mset", "#{subscription_prefix}:id", subscription.data.id,
										"#{subscription_prefix}:offer", subscription.data.offer.id,
										"#{subscription_prefix}:next_capture_at", subscription.data.next_capture_at,
										"#{subscription_prefix}:created_at", subscription.data.created_at,
										"#{subscription_prefix}:updated_at", subscription.data.updated_at,
										"#{subscription_prefix}:canceled_at", subscription.data.canceled_at,
										"#{subscription_prefix}:payment", subscription.data.payment.id,
										"#{subscription_prefix}:client", subscription.data.client.id,
										"#{subscription_prefix}:notified", false ]

								]).exec (err) ->
									console.log err
									return cb err if err
									console.log "\t subscription created on Redis"
									cb null, subscription
			else
				cb new check.Error "Missing offer !"

		# notify user
		(cb) ->
			console.log "notified user not yet implemented !"
			console.log "BUT EVERYTHING IS OK ;-)"
			cb()

	], (err, result) ->
		return callback err if err
		return callback null, result
