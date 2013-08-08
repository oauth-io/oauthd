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
	console.log("UPDATE");

# create an Offer
exports.createOffer = (amount, name, currency, interval, callback) ->

	console.log("create Offer "+ name + " of " + amount + " " + currency + " during " + interval);
	prefix = "pm:offers"

	db.redis.sismember [ "#{prefix}:#{name}", 1 ], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but you have already added " + name.toUpperCase() if res == 1

		paymill.offers.create
			amount: amount
			currency: currency
			interval: interval
			name: name
		,(err, offer) ->
			return callback err if err

			console.log "offer id " + offer.data.id

			db.redis.multi([
				[ 'sadd', "#{prefix}", name ],
				[ 'sadd', "#{prefix}:#{name}", 1],
				[ 'mset', "#{prefix}:#{name}:id", offer.data.id,
						"#{prefix}:#{name}:currency", offer.data.currency,
						"#{prefix}:#{name}:interval", offer.data.interval,
						"#{prefix}:#{name}:created_at", offer.data.created_at,
						"#{prefix}:#{name}:updated_at", offer.data.updated_at,
						"#{prefix}:#{name}:amount", offer.data.amount,
					  	"#{prefix}:#{name}:subscription_count:active", offer.data.subscription_count.active,
					  	"#{prefix}:#{name}:subscription_count:inactive", offer.data.subscription_count.inactive
				 ]
				]).exec (err) ->
					return callback err if err
					return callback null, offer

# delete an Offer
exports.removeOffer = check 'string', (name, callback) ->
	prefix = 'pm:offers:' + name
	db.redis.sismember ['pm:offers' , name], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but the plan " + plan.toUpperCase() + " doesn't exist anymore" if res == 0

		db.redis.multi([
			[ 'del', prefix+':id', prefix+':currency', prefix+':interval',prefix+':created_at',prefix+':updated_at',prefix+':amount', prefix+':subscription_count:active',prefix+':subscription_count:inactive',prefix ]
			[ 'srem', 'pm:offers', name],
		]).exec (err, replies) ->
			return callback err if err
			return callback null, name

# getList of Offer
exports.getOffersList = (callback) ->

	prefix = "pm:offers"

	db.redis.smembers "#{prefix}", (err, offers) ->
		return callback err if err
		return callback null, [] if not offers.length

		cmds = []
		tmpName = []
		j = 0;
		for p in offers
			tmpName[j++] = p
			cmds.push [ "get", "#{prefix}:#{p}:id"]
			cmds.push [ "get", "#{prefix}:#{p}:currency"]
			cmds.push [ "get", "#{prefix}:#{p}:interval"]
			cmds.push [ "get", "#{prefix}:#{p}:created_at"]
			cmds.push [ "get", "#{prefix}:#{p}:updated_at"]
			cmds.push [ "get", "#{prefix}:#{p}:amount"]
			cmds.push [ "get", "#{prefix}:#{p}:subscription_count:active"]
			cmds.push [ "get", "#{prefix}:#{p}:subscription_count:inactive"]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of offers
				offers[i] = id:res[i * 8], currency:res[i * 8 + 1], interval:res[i * 8 + 2], created_at:res[i * 8 + 3], updated_at:res[i * 8 + 4], amount:res[i * 8 + 5], subscription_count:active:res[i * 8 + 6], subscription_count:inactive:res[i * 8 + 7]
				offers[i].name = tmpName[i]

			return callback null, offers