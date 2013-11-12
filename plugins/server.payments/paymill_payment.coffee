emailer = require 'nodemailer'
PaymillBase = require './paymill_base'
{ db, check, config } = shared = require '../shared'

class PaymillPayment

	@id = null
	@token = null
	@client = null

	@isNew = true

	constructor : (@id) ->
		if @id?
			PaymillBase.paymill.payments.details @id, (err, payment) =>
				return null if err
				return @populate payment.data

	save : (callback) ->

		@isNew = false if @id?
		@isNew = true if not @id?

		if @isNew
			payment_obj = @prepare()

			PaymillBase.paymill.payments.create payment_obj, (err, payment) =>
				return callback err if err

				@id = payment.data.id

				payment_prefix = "#{PaymillBase.payments_root_prefix}:#{@client.user_id}:#{@id}"

				db.redis.multi([

					[ "hset", "#{PaymillBase.payments_root_prefix}:#{@client.user_id}", "current_payment", @id ],

					[ "sadd", "#{PaymillBase.payments_root_prefix}:payments_id", @id ],

					[ "mset", "#{payment_prefix}:client", payment.data.client,
					"#{payment_prefix}:card_type", payment.data.card_type,
					"#{payment_prefix}:country", payment.data.country,
					"#{payment_prefix}:expire_month", payment.data.expire_month,
					"#{payment_prefix}:expire_year", payment.data.expire_year,
					"#{payment_prefix}:card_holder", payment.data.card_holder,
					"#{payment_prefix}:last4", payment.data.last4,
					"#{payment_prefix}:created_at", payment.data.created_at ]

				]).exec (err) ->
					return callback err if err
					return callback null, @

	getById : (@id, callback) ->

		payment_prefix = "#{PaymillBase.payments_root_prefix}:#{@client.id}:#{@id}"
		console.log "get infos for #{payment_prefix}"
		db.redis.mget ["#{payment_prefix}:client",
					"#{payment_prefix}:card_type"
					"#{payment_prefix}:country",
					"#{payment_prefix}:expire_month",
					"#{payment_prefix}:expire_year",
					"#{payment_prefix}:card_holder",
					"#{payment_prefix}:last4",
					"#{payment_prefix}:created_at" ]
		, (err, res) ->
			return callback err if err
			return callback null, @populate(res)

	populate : (data) ->
		return { id : @id, client : data.client, card_type : data.card_type, last4 : data.last4 }

	prepare : ->
		return { token : @token, client : @client.id }

exports = module.exports = PaymillPayment