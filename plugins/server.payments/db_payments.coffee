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
		amount: ''
		offer: ''
		payment: ''

	o_prefix = "o:#{client_id}"
	h_u_prefix = "u:mails"

	async.series [

		# create Paymill user
		(cb) ->
			console.log "creating Paymill user..."
			db.redis.mget ["#{o_prefix}:pm_user_id"], (err, order) ->
				return cb err if err
				#return cb new check.Error "Order exists..., is it an update ?" if order[0]?

				client_obj.email = client_email

				# create Paymill user
				paymill.clients.create client_obj, (err, client) ->
					return cb err if err

					id = client.data.id # Paymill id
					client_obj.id = id

					# Paymill user id to Redis
					db.redis.set "#{o_prefix}:pm_user_id", id, (err, res) ->
						return cb err if err
						cb()

		# create payment
		(cb) ->
			console.log "creating Paymill payment..."

			payment_obj.token = data.token
			payment_obj.client = client_obj.id

			paymill.payments.create payment_obj, (err, payment) ->

				# Payment : credit card infos...
				db.redis.set "#{o_prefix}:pm_payment_id", payment.data.id, (err, res) ->
					return cb myError if err
					cb null

		# create transaction
		(cb) ->
			console.log "creating Paymill subscription..."

			subscription_obj.amount = data.amount * 2
			subscription_obj.offer = data.offer
			subscription_obj.payment = payment_obj.id

			paymill.subscriptions.create subscription_obj, (err, subscription) ->
				return cb err if err
				cb null

		# notify user
		(cb) ->
			console.log "notify user"
			console.log "ok"
			cb null

	], (err, result) ->
		return callback err if err
		return callback null, result

exports.update = (offer_id, callback) ->