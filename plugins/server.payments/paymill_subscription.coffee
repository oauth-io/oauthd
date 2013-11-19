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

			@isNew = true

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
						console.log err if err
						return callback err if err
						console.log "created non fr"
						return callback null, res

		else # update (upgrade or downgrade)

			console.log "update subscription..."
			@isNew = false
			db.redis.multi([

				[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_subscription"],
				[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}", "current_offer" ]

			]).exec (err, res) =>
				return callback err if err
				return callback new check.Error "An error occured, please contact support@oauth.io" if not res?
				return callback new check.Error "You can not subscribe to the same plan" if res[1] == @offer.id

				db.redis.get "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:#{res[0]}:created_at", (err, created_at) =>

					console.log "get info from #{@client.id}..."
					PaymillBase.paymill.clients.details @client.id, (err, client) =>

						@old_subscription = client.data.subscription[client.data.subscription.length - 1]

						PaymillBase.paymill.subscriptions.remove res[0], (err, subscription_updated) =>

							Payment.getCart @client.user_id, (err, success) =>

								cart = success
								hasTVA = parseFloat(cart.VAT_percent) != 0

								subscription_obj = @prepare()

								if hasTVA # true => FR
									plan_fr = (cart.plan_name + "FR").toLowerCase()
									Offer.getOfferByName plan_fr, (err, offer) =>

										# assign FR plan
										@offer = { id: offer.offer }
										subscription_obj = @prepare()

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
			console.log err if err
			return callback new check.Error err.response.error if err

			subscription_prefix = "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:#{subscription.data.id}"
			db.redis.multi([

				#[ "hset", "#{PaymillBase.subscriptions_root_prefix}:#{@client.user_id}:history", subscription.data.offer.id, subscription.data.created_at ],

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

				if not @isNew

					console.log "old subscription id #{@old_subscription.id}"
					console.log "new subscription id #{subscription.data.id}"
					PaymillBase.paymill.transactions.list description:@old_subscription.id, (err, transaction) =>

						# subscription.data.created_at = 1372803758
						# transaction.data[transaction.data.length - 1].created_at = 1371507758
						# @old_subscription.next_capture_at = 1374099758

						oldSubDate1 = new Date(transaction.data[transaction.data.length - 1].created_at * 1000)
						oldSubDate2 = new Date(@old_subscription.next_capture_at * 1000)
						newSubDate = new Date(subscription.data.created_at * 1000)
						nbDaysDiff = Math.floor( ((newSubDate - oldSubDate1) / (1000 * 60 * 60 * 24)) * 100) / 100

						console.log "NbDaysDiff before #{nbDaysDiff}"
						nbDaysDiff = 1 if nbDaysDiff >= 0.06 and nbDaysDiff <= 0.99
						console.log "NbDaysDiff adjustement #{nbDaysDiff}"

						oldNextCapture = new Date(oldSubDate2.getYear(), oldSubDate2.getMonth(), oldSubDate2.getDate())
						oldLastCapture = new Date(oldSubDate1.getYear(), oldSubDate1.getMonth(), oldSubDate1.getDate())
						# console.log "Last capture of last plan : #{oldLastCapture.getDate()}/#{oldLastCapture.getMonth() + 1}/#{oldLastCapture.getFullYear()}"
						# console.log "Next capture of last plan : #{oldNextCapture.getDate()}/#{oldNextCapture.getMonth() + 1}/#{oldNextCapture.getFullYear()}"

						nbDays = ((oldNextCapture - oldLastCapture) / (1000 * 60 * 60 * 24))

						# console.log "=========================================================================================="
						# console.log "Nb Days Diff = #{nbDaysDiff} day(s) (#{oldSubDate1.getDate()}/#{oldSubDate1.getMonth() + 1}/#{oldSubDate1.getFullYear()} to #{newSubDate.getDate()}/#{newSubDate.getMonth() + 1}/#{newSubDate.getFullYear()})"
						# console.log "Nb Days Total = #{nbDays} day(s) (#{oldLastCapture.getDate()}/#{oldLastCapture.getMonth() + 1}/#{oldLastCapture.getFullYear()} to #{oldNextCapture.getDate()}/#{oldNextCapture.getMonth() + 1}/#{oldNextCapture.getFullYear()})"

						last_price = @old_subscription.offer.amount / 100
						# console.log "Last price: $#{last_price}"
						refunded = Math.floor( ((nbDaysDiff / nbDays) * last_price) * 100) / 100
						refund_total = Math.floor((last_price - refunded) * 100) / 100

						# console.log "(#{nbDaysDiff} / #{nbDays}) * #{last_price} = #{refunded} , $#{refund_total} refunded (You have used #{nbDaysDiff} days(s) at $#{last_price} of your last plan...)"
						# console.log "------------------------------------------------------------------------------------------"
						# console.log "You have paid for your new plan $#{subscription.data.offer.amount / 100}"
						# console.log "Refund total: $#{refund_total}"
						# console.log "------------------------------------------------------------------------------------------"
						# console.log "=========================================================================================="

						if refund_total > 0
							transaction_id = transaction.data[0].id
							if transaction.data[0].refunds == null
								refund_total = refund_total * 100
								PaymillBase.paymill.refunds.refund transaction_id, refund_total, '', (err, refund) =>
									console.log err if err
									return callback err if err
									console.log "#{refund_total} refunded..."
									console.log "refunded id #{refund.data.id}"
							else
								console.log "old transaction #{transaction_id} already refunded !"
						else
							console.log "no refund at $0 !"
				else
					console.log "new sub no refund!"

				Payment.addOrder @client.user_id, subscription, (err, res) =>
					return callback err if err

					Payment.delCart @client.user_id, (err, res) =>
						#return callback err if err
						return callback null, subscription

	# TEST
	refund : (callback) ->

		db.redis.hget "#{PaymillBase.subscriptions_root_prefix}:#{@user_id}", "current_subscription", (err, current_subscription) =>

			if current_subscription?

				PaymillBase.paymill.subscriptions.details current_subscription, (err, subscription_details) =>
					return callback err if err

					console.log "old subscription id #{subscription_details.data.id}"
					PaymillBase.paymill.transactions.list description:subscription_details.data.id, (err, transaction) =>

						oldSubDate1 = new Date(transaction.data[transaction.data.length - 1].created_at * 1000)
						oldSubDate2 = new Date(subscription_details.data.next_capture_at * 1000)
						newSubDate = new Date()
						nbDaysDiff = Math.floor( ((newSubDate - oldSubDate1) / (1000 * 60 * 60 * 24)) * 100) / 100

						console.log nbDaysDiff
						nbDaysDiff = 1 if nbDaysDiff >= 0.06 and nbDaysDiff <= 0.99
						console.log nbDaysDiff

						oldNextCapture = new Date(oldSubDate2.getYear(), oldSubDate2.getMonth(), oldSubDate2.getDate())
						oldLastCapture = new Date(oldSubDate1.getYear(), oldSubDate1.getMonth(), oldSubDate1.getDate())

						nbDays = ((oldNextCapture - oldLastCapture) / (1000 * 60 * 60 * 24))

						last_price = subscription_details.data.offer.amount / 100
						refunded = Math.floor( ((nbDaysDiff / nbDays) * last_price) * 100) / 100
						refund_total = Math.floor((last_price - refunded) * 100) / 100

						if refund_total > 0
							transaction_id = transaction.data[0].id
							if transaction.data[0].refunds == null
								refund_total = refund_total * 100
								PaymillBase.paymill.refunds.refund transaction_id, refund_total, '', (err, refund) =>
									console.log err if err
									return callback err if err
									console.log "#{refund_total} refunded..."
									console.log "refunded id #{refund.data.id}"
									return callback null
							else
								console.log "old transaction #{transaction_id} already refunded !"
								return callback new check.Error "Already refunded"
						else
							console.log "no refund at $0 !"
							return callback new check.Error "Can't refund at $0"
			else
				return callback new check.Error "No subscription"

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