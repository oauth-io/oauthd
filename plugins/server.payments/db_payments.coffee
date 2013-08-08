async = require 'async'
Mailer = require '../../lib/mailer'
{ db, check, config } = shared = require '../shared'

paymill = require('paymill-node')(config.paymill.secret_key)

exports.process = (data, client, callback) ->

	client_id = client.id
	client_email = client.mail

	client_obj =
		email : ''

	payment_obj =
		token: ''
		client: ''

	subscription_obj =
		client: ''
		offer: ''
		payment: ''

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
					# create Paymill user
					paymill.clients.create client_obj, (err, client) ->
						return cb err if err

						id = client.data.id # Paymill id
						client_obj.id = id

						# Paymill user id to Redis
						db.redis.hset "#{subscriptions_root_prefix}", client_id, id, (err, res) ->
							return cb err if err
							cb()
				else
					console.log "\t user exists with id #{current_id}"
					cb()

		# create payment
		(cb) ->
			console.log "creating Paymill payment..."

			# get payment_id or define a new

			payment_obj.token = data.token
			payment_obj.client = client_obj.id

			paymill.payments.create payment_obj, (err, payment) ->
				return cb err if err

				payment_obj.id = payment.data.id

				# Payment : credit card infos...
				payment_prefix = "#{payments_root_prefix}:#{client_id}:#{payment.data.id}"

				db.redis.mset [
					"#{payment_prefix}:client", payment.data.client,
					"#{payment_prefix}:card_type", payment.data.card_type,
					"#{payment_prefix}:country", payment.data.country,
					"#{payment_prefix}:expire_month", payment.data.expire_month,
					"#{payment_prefix}:expire_year", payment.data.expire_year,
					"#{payment_prefix}:card_holder", payment.data.card_holder,
					"#{payment_prefix}:last4", payment.data.last4,
					"#{payment_prefix}:created_at", payment.data.created_at
				], (err) ->
					return cb err if err
					console.log "\t payment created"
					cb()

		# create subscription
		(cb) ->

			if data.offer # it's a subscription to an offer

				console.log "creating Paymill subscription..."

				subscription_obj.client = client_obj.id
				subscription_obj.offer = data.offer
				subscription_obj.payment = payment_obj.id

				paymill.subscriptions.create subscription_obj, (err, subscription) ->
					return cb err if err

					console.log "\t subscription created on Paymill"
					console.log "\t creating on redis..."

					subscription_prefix = "#{subscriptions_root_prefix}:#{client_id}:#{subscription.data.id}"

					db.redis.multi([

						[ "sadd", "#{subscriptions_root_prefix}", subscription.data.id ],

						[ "mset", "#{subscription_prefix}:id", subscription.data.id,
							"#{subscription_prefix}:amount", subscription.data.amount,
							"#{subscription_prefix}:status", subscription.data.status
							"#{subscription_prefix}:currency", subscription.data.id,
							"#{subscription_prefix}:created_at", subscription.data.id,
							"#{subscription_prefix}:updated_at", subscription.data.id,
							"#{subscription_prefix}:response_code", subscription.data.id,
							"#{subscription_prefix}:short_id", subscription.data.id,
							"#{subscription_prefix}:payment", subscription.data.id
							"#{subscription_prefix}:notified", false ]

					]).exec (err, res) ->
						return cb err if err
						console.log "\t prayment created on Redis"
						cb()
			else
				cb new check.Error "Missing offer !"

		# notify user
		(cb) ->
			console.log "notify user"
			console.log "ok"
			cb()

	], (err, result) ->
		return callback err if err
		return callback null, result