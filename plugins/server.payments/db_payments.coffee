async = require 'async'
Mailer = require '../../lib/mailer'
{ db, check, config } = shared = require '../shared'

exports.process = (data, client, callback) ->

	paymill = require('paymill-node')(config.paymill.secret_key)

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

	o_prefix = "o:#{client_id}"

	async.series [

		# create Paymill user
		(cb) ->
			console.log "creating Paymill user..."
			db.redis.hget ["#{o_prefix}", "pm_user_id"], (err, id) ->
				return cb err if err

				client_obj.id = id if id?
				client_obj.email = client_email

				if not id?
					# create Paymill user
					paymill.clients.create client_obj, (err, client) ->
						return cb err if err

						id = client.data.id # Paymill id
						client_obj.id = id

						# Paymill user id to Redis
						db.redis.hset "#{o_prefix}", "pm_user_id", id, (err, res) ->
							return cb err if err
							cb()
				else
					cb()

		# create payment
		(cb) ->
			console.log "creating Paymill payment..."

			# get payment_id or define a new

			payment_obj.token = data.token
			payment_obj.client = client_obj.id

			paymill.payments.create payment_obj, (err, payment) ->

				payment_obj.id = payment.data.id

				# Payment : credit card infos...
				db.redis.hset "#{o_prefix}", "pm_payment_id", payment.data.id, (err, res) ->
					return cb myError if err
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

					db.redis.multi [


						[ "sadd", "#{o_prefix}:subscriptions", subscription.data.id],

						[ "hset", "#{o_prefix}:subscriptions:id", subscription.data.id,
							"#{o_prefix}:subscriptions:amount", subscription.data.amount,
							"#{o_prefix}:subscriptions:status", subscription.data.status
							"#{o_prefix}:subscriptions:currency", subscription.data.id,
							"#{o_prefix}:subscriptions:created_at", subscription.data.id,
							"#{o_prefix}:subscriptions:updated_at", subscription.data.id,
							"#{o_prefix}:subscriptions:response_code", subscription.data.id,
							"#{o_prefix}:subscriptions:short_id", subscription.data.id,
							"#{o_prefix}:subscriptions:payment", subscription.data.id
							"#{o_prefix}:subscriptions:notified", false ]

					], (err) ->
						return cb err if err
						cb()

		# notify user
		(cb) ->
			console.log "notify user"
			console.log "ok"
			cb()

	], (err, result) ->
		return callback err if err
		return callback null, result

exports.update = (offer_id, callback) ->