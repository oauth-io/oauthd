emailer = require 'nodemailer'
PaymillBase = require './paymill_base'
PaymillSubscription = require './paymill_subscription'
PaymillPayment = require './paymill_payment'
{ db, check, config } = shared = require '../shared'

class PaymillClient

	# String
	@id

	# Integer (user id web)
	@user_id

	# String
	@email

	# String
	@description

	# Boolean
	@isNew

	constructor: (@id) ->
		if @id?
			PaymillBase.paymill.clients.details @id, (err, client) =>
				return null if err
				return @populate client.data

	save: (callback) ->

		@isNew = false if @id?
		@isNew = true if not @id?

		console.log @isNew
		if @isNew
			client_obj = @prepare()

			PaymillBase.paymill.clients.create client_obj, (err, client) =>
				return callback err if err
				@id = client.data.id

				# Paymill user id to Redis
				db.redis.hset "#{PaymillBase.subscriptions_root_prefix}", @user_id, @id, (err, res) =>
					return callback err if err
					return callback null, @

	getSubscriptions: (callback) ->
		db.redis.hget "#{PaymillBase.subscriptions_root_prefix}", @user_id, (err, res) ->
			return callback err if err
			return callback null, [] if not res?

			PaymillBase.paymill.clients.details res, (err, client) ->
				return callback null if err
				return callback null, [] if not client.data.subscription?

				subscriptions = client.data.subscription
				ret = []
				i = 0
				for sub in subscriptions
					if sub.offer.name?
						sub.offer.name = sub.offer.name.substr 0, sub.offer.name.length - 2  if sub.offer.name.substr(sub.offer.name.length - 2, 2) is 'fr'
						ret[i] = name: sub.offer.name, amount: (sub.offer.amount / 100), created_at: sub.payment.created_at*1000, last4: sub.payment.last4, card_type: sub.payment.card_type
						i++

				return callback null, ret

	getPayments: (callback) ->
		db.redis.hget "#{PaymillBase.subscriptions_root_prefix}", @user_id, (err, res) ->
			return callback err if err
			return callback null, [] if not res?

			PaymillBase.paymill.clients.details res, (err, client) ->
				return null if err
				return callback null, client.data.payment

	getCurrentPayment: (callback) ->
		db.redis.hget ["#{PaymillBase.payments_root_prefix}:#{@user_id}", "current_payment"], (err, res) ->
			return callback err if err
			return callback null, [] if not res

			payment = new PaymillPayment()
			payment.getById res, (err, card) ->
				return callback err if err
				return callback null, card

	getCurrentSubscription: (callback) ->
		db.redis.hget ["#{PaymillBase.subscriptions_root_prefix}:#{@user_id}", "current_subscription"], (err, res) ->
			return callback err if err
			return callback null, res

	getCurrentPlan: (callback) ->
		db.redis.hget ["#{PaymillBase.subscriptions_root_prefix}:#{@user_id}", "current_offer"], (err, offer) ->
			return callback err if err
			db.redis.hget "#{PaymillBase.offers_root_prefix}:offers_id", offer, (err, offer_name) ->
				return callback err if err
				db.redis.get "#{PaymillBase.offers_root_prefix}:#{offer_name}:name", (err, res) ->
					return callback err if err
					res = res.substr 0, res.length - 2  if res.substr(res.length - 2, 2) is 'fr'
					return callback null, res

	populate: (data) ->
		return { id : data.id, email : data.email, description : data.description }

	prepare: ->
		return { email : @email, description : @description }

exports = module.exports = PaymillClient