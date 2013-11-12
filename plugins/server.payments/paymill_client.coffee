emailer = require 'nodemailer'
PaymillBase = require './paymill_base'
PaymillSubscription = require './paymill_subscription'
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
				return null if err
				return callback null, client.data.subscription


	getCurrentSubscription: (callback) ->

		# exists on Redis
		db.redis.hget ["#{PaymillBase.subscriptions_root_prefix}:#{@user_id}", "current_subscription"], (err, res) ->
			return callback err if err
			# res : current subscription id
			subscription = new PaymillSubscription res
			return callback null, subscription


	fillObject: (data) ->
		@email = data.email
		@description = data.description
		@

	populate: (data) ->
		return { id : data.id, email : data.email, description : data.description }

	prepare: ->
		return { email : @email, description : @description }

exports = module.exports = PaymillClient