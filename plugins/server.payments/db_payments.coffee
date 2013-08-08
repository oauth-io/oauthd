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

					console.log "\tnew user detected"
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
					console.log "\tuser exists with id #{id}"
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
				db.redis.hset "#{o_prefix}", "pm_payment_id", payment.data.id, (err, res) ->
					return cb err if err
					console.log "\t prayment created"
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
					subscription_prefix = "#{o_prefix}:subscriptions:#{subscription.data.id}"
					console.log "\t creating on redis..."

					db.redis.multi([

						[ "sadd", "#{o_prefix}:subscriptions", subscription.data.id ],

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
		return callback null, status:"success"