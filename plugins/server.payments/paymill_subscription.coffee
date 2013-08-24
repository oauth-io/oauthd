emailer = require 'nodemailer'
PaymillBase = require './paymill_base'
{ db, check, config } = shared = require '../shared'

class PaymillSubscription

	# String
	@id = null

	# Timestamp
	@next_capture = null

	# Timestamp
	@canceled_at = null

	# Boolean
	@canceled_at = null

	# Object
	@offer = null

	# Object
	@client = null

	# Object
	@payment = null

	constructor : (@id) ->
		if @id?
			PaymillBase.paymill.subscriptions.details @id, (err, subscription_details) =>
				return null


	getCurrent : (@client_id, callback) ->

		# exists on Redis
		db.redis.hget ["#{PaymillBase.subscriptions_root_prefix}:#{@client_id}", "current_subscription"], (err, res) ->
			return callback err if err

			# exists on Paymill
			PaymillBase.paymill.subscriptions.details res, (err, subscription_details) ->
				return callback err if err
				return callback null, populate(subscription_details)

	getById : (sub_id) ->
		PaymillBase.paymill.subscriptions.details sub_id, (err, subscription_details) ->
			return callback err if err
			return callback null, populate(subscription_details)

	save : (callback) ->

		if not @id? # create subscription

			payment_obj = @prepare()

			PaymillBase.paymill.subscriptions.create payment_obj, (err, subscription) =>
				return callback err if err

				subscription_prefix = "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:#{subscription.data.id}"

				db.redis.multi([

					[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:history", subscription.data.offer.id, subscription.data.created_at ],

					[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_subscription", subscription.data.id ],

					[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_offer", @offer.id ],

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
					return callback err if err
					return callback null, subscription

		else # update (upgrade or downgrade)

			console.log "update subscription..."
			db.redis.multi([

				[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_subscription"],
				[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_offer" ]

			]).exec (err, res) =>
				return callback err if err
				return callback new check.Error "An error occured, please contact support@oauth.io" if not res?
				return callback new check.Error "You can not subscribe to the same plan" if res[1] == @offer.id

				PaymillBase.paymill.subscriptions.remove res[0], (err, subscription_updated) =>

					subscription_obj = @prepare()
					subscription_obj.start_at = @next_capture

					PaymillBase.paymill.subscriptions.create subscription_obj, (err, subscription) =>
						console.log err if err
						return callback err if err

						subscription_prefix = "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:#{subscription.data.id}"

						db.redis.multi([

							[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:history", subscription.data.created_at, subscription.data.offer.id ],

							[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_subscription", subscription.data.id ],

							[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_offer", @offer.id ],

							[ "mset", "#{subscription_prefix}:id", subscription.data.id,
								"#{subscription_prefix}:offer", subscription.data.offer.id,
								"#{subscription_prefix}:next_capture_at", subscription.data.next_capture_at,
								"#{subscription_prefix}:created_at", subscription.data.created_at,
								"#{subscription_prefix}:updated_at", subscription.data.updated_at,
								"#{subscription_prefix}:canceled_at", subscription.data.canceled_at,
								"#{subscription_prefix}:payment", subscription.data.payment.id,
								"#{subscription_prefix}:client", subscription.data.client.id,
								"#{subscription_prefix}:notified", false ]

						]).exec (err) =>
							return callback err if err
							console.log "subscription updated"
							return callback null, @populate subscription

	populate : (data) ->
		return
		{
			id : @id,
			client : data.client,
			offer : data.offer,
			payment : data.Payment.id,
			next_capture_at : data.next_capture_at,
			canceled_at : data.canceled_at
		}

	prepare : ->
		return { client : @client.id, offer : @offer.id, payment : @payment.id }

	#exists : (id) ->

	# details : (id) ->

	# remove : (subscription) ->


exports = module.exports = PaymillSubscription