emailer = require 'nodemailer'
PaymillBase = require './paymill_base'
Payment = require './db_payments'
Offer = require '../server.pricing/db_pricing'

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
	@cart = null

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

			Payment.getCart @client.user_id, (err, success) =>

				cart = success
				hasTVA = parseFloat(cart.VAT_percent) != 0

				if hasTVA # true => FR
					plan_fr = (cart.plan_name + "FR").toLowerCase()
					Offer.getOfferByName plan_fr, (err, offer) =>

						# assign FR plan
						@offer = { id: offer.offer }

						payment_obj = @prepare()
						@create payment_obj, (err, res) ->
							console.log err if err
							return callback err if err
							console.log "created fr"
							return callback null, res
				else

					payment_obj = @prepare()
					@create payment_obj, (err, res) ->
						return callback err if err
						console.log "created non fr"
						return callback null, res

		else # update (upgrade or downgrade)

			console.log "update subscription..."
			db.redis.multi([

				[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_subscription"],
				[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_offer" ]

			]).exec (err, res) =>
				return callback err if err
				return callback new check.Error "An error occured, please contact support@oauth.io" if not res?
				return callback new check.Error "You can not subscribe to the same plan" if res[1] == @offer.id

				# recup ancienne données de la souscription
				#db.redis.hget "#{PaymillBase.offers_root_prefix}:offers_id", res[0], (err, offer_name) ->
				console.log "get old subscription details...#{res[0]}"
				PaymillBase.paymill.subscriptions.details res[0], (err, old_subscription_details) =>

					#PaymillBase.paymill.subscriptions.remove res[0], (err, subscription_updated) =>

					sub_update_params =
						cancel_at_period_end: true # cancel when we have the money !!!
						offer: res[1] # old subscription

					console.log "update old subscription...#{res[0]} with " + sub_update_params
					PaymillBase.paymill.subscriptions.update res[0], sub_update_params, (err, subscription_updated) =>

						console.log subscription_updated

						Payment.getCart @client.user_id, (err, success) =>

							cart = success
							hasTVA = parseFloat(cart.VAT_percent) != 0

							subscription_obj = @prepare()
							subscription_obj.start_at = old_subscription_details.data.next_capture_at

							if hasTVA # true => FR
								plan_fr = (cart.plan_name + "FR").toLowerCase()
								Offer.getOfferByName plan_fr, (err, offer) =>

									# assign FR plan
									@offer = { id: offer.offer }
									subscription_obj = @prepare()
									subscription_obj.start_at = old_subscription_details.data.next_capture_at

									# affect new subsription (VAT included)
									@create subscription_obj, (err, res) ->
										return callback err if err
										console.log "created fr"
										return callback null, res
							else

								#payment_obj = @prepare()
								# affect new subscription (without VAT)
								@create subscription_obj, (err, res) ->
									return callback err if err
									console.log "created non fr"
									return callback null, res

	create : (sub_obj, callback) ->

		PaymillBase.paymill.subscriptions.create sub_obj, (err, subscription) =>
			return callback new check.Error err.response.error if err
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

			]).exec (err) =>
				return callback err if err

				Payment.addOrder @client.user_id, subscription, (err, res) =>
					return callback err if err

					Payment.delCart @client.user_id, (err, res) ->
						return callback err if err
						return callback null, subscription

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

exports = module.exports = PaymillSubscription