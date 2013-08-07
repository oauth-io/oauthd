async = require 'async'
Mailer = require '../../lib/mailer'
{ db, check, config } = shared = require '../shared'

exports.process = (data, client_id, callback) ->
	
	return callback new check.Error 'client is empty' if not client_id?

	paymill = require('paymill-node')(config.paymill.secret_key)

	client_obj =		
		email : ''
		
	payment_obj =  null
	transaction_obj = null
	subscription_obj = null

	o_prefix = "o:#{client_id}"	
	h_u_prefix = "u:mails"

	async.series [
		
		# check if user had paid
		(cb) ->
			console.log "check if user had pay..."
			db.redis.mget ["#{o_prefix}:offer_id"], (err, order) ->
				return callback err if err
				return callback new check.Error "Order exists" if order[0]?

				client_obj.email = data.email
				paymill.client.create client_obj, (err, client) ->
					return callback err if err
					
					db.redis.sadd o_prefix, client.data.id, (err, res) ->
						return callback err if err
						
						cb null

		# create client and payment
		(cb) ->
			# console.log "cerate payment"
			# paymill.payment.create payment_obj, (err, payment) ->
			# 	return callback err if err
			console.log client_obj
			cb null


		# create transaction
		(cb) ->
			console.log "creating subscription..."

			# transaction_obj =
			# 	amount: data.amount * 100
			# 	payment : payment_obj.id
			# 	currency: "EUR"
			# 	token: ''
			#	client_id: ''

			# paymill.transaction.create transaction_obj, (err, transaction) ->
			# 	return callback err if err
			# 	console.log "ok"

			# paymill.subscription.create subscription_obj, (err, subscription) ->
			# 	return callback err if err
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