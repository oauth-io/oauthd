# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#
#

async = require 'async'
restify = require 'restify'
{ db, check, config } = shared = require '../shared'
paymill = require('paymill-node')(config.paymill.secret_key)
PaymillBase = require '../server.payments/paymill_base'
Payment = require '../server.payments/db_payments'

# create an Offer
exports.createOffer = (data, callback) ->

	prefix = "pm:offers"
	name = data.name.toLowerCase()
	status = data.status

	db.redis.sismember [ "#{prefix}", name ], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but you have already added " + name.toUpperCase() if res == 1

		async.series [

			(cb) => # HT

				paymill.offers.create
					amount: data.amount
					currency: data.currency
					interval: data.interval
					name: name
				,(err, offer) ->
					console.error err if err
					return callback err if err

					offer.data.name = name
					offer.data.status = status
					offer.data.nbConnection = data.nbConnection
					offer.data.nbApp = data.nbApp
					offer.data.nbProvider = data.nbProvider
					offer.data.responseDelay = data.responseDelay

					db.redis.multi([

						[ 'sadd', "#{prefix}", name ],

						[ 'sadd', "#{prefix}:#{status}", name ],

						[ 'mset', "#{prefix}:#{name}:id", offer.data.id,
								"#{prefix}:#{name}:name", name,
								"#{prefix}:#{name}:currency", offer.data.currency,
								"#{prefix}:#{name}:interval", offer.data.interval,
								"#{prefix}:#{name}:created_at", offer.data.created_at,
								"#{prefix}:#{name}:updated_at", offer.data.updated_at,
								"#{prefix}:#{name}:amount", offer.data.amount,
								"#{prefix}:#{name}:status", status,
								"#{prefix}:#{name}:nbConnection", data.nbConnection,
								"#{prefix}:#{name}:nbApp", offer.data.nbApp,
								"#{prefix}:#{name}:nbProvider", offer.data.nbProvider,
								"#{prefix}:#{name}:responseDelay", offer.data.responseDelay],

						[ "hset", "#{prefix}:offers_id", offer.data.id, name ]

					]).exec (err) ->
						return cb err if err
						cb null, offer.data

			(cb) => # TTC (20%)

				total_ht = data.amount / 100
				tva = 0.20
				total_tva = Math.floor((total_ht * tva) * 100) / 100
				total_ttc = ((total_ht + total_tva) * 100 ) / 100
				total_ttc *= 100 # for paymill (e.g 230.4 => 23040)
				status = 'private'
				parent = name
				name += "fr"

				console.log total_ttc
				paymill.offers.create
					amount: total_ttc
					currency: data.currency
					interval: data.interval
					name: name
				,(err, offer) ->
					console.log err if err
					return cb err if err

					offer.data.name = name
					offer.data.status = status
					offer.data.nbConnection = data.nbConnection
					offer.data.nbApp = data.nbApp
					offer.data.nbProvider = data.nbProvider
					offer.data.responseDelay = data.responseDelay
					offer.data.parent = parent

					db.redis.multi([

						[ 'sadd', "#{prefix}", name ],

						[ 'sadd', "#{prefix}:#{status}", name ],

						[ 'mset', "#{prefix}:#{name}:id", offer.data.id,
								"#{prefix}:#{name}:name", name,
								"#{prefix}:#{name}:currency", offer.data.currency,
								"#{prefix}:#{name}:interval", offer.data.interval,
								"#{prefix}:#{name}:created_at", offer.data.created_at,
								"#{prefix}:#{name}:updated_at", offer.data.updated_at,
								"#{prefix}:#{name}:amount", offer.data.amount,
								"#{prefix}:#{name}:status", status,
								"#{prefix}:#{name}:nbConnection", data.nbConnection,
								"#{prefix}:#{name}:nbApp", offer.data.nbApp,
								"#{prefix}:#{name}:nbProvider", offer.data.nbProvider,
								"#{prefix}:#{name}:responseDelay", offer.data.responseDelay,
								"#{prefix}:#{name}:parent", parent ],

						[ "hset", "#{prefix}:offers_id", offer.data.id, name ]

					]).exec (err) ->
						return cb err if err
						cb null, offer.data

		], (err, res) ->
			return callback err if err
			return callback null, res

# delete an Offer
exports.removeOffer = (name, callback) ->
	prefix = 'pm:offers:' + name
	prefix_ttc = "pm:offers:#{name}fr"
	name = name.toLowerCase()
	name_ttc = "#{name}fr".toLowerCase()

	db.redis.sismember ['pm:offers' , name], (err, res) ->
		return callback err if err
		return callback new check.Error "#{name.toUpperCase()} not found !" if not res

		async.series [
			(cb) => # HT
				db.redis.mget "#{prefix}:id", "#{prefix}:status", (err, res) ->
					return callback err if err

					id_offer = res[0]
					status = res[1]

					paymill.offers.remove id_offer, (err, offer) ->
						#return callback err if err

						db.redis.multi([
							[ 'del', prefix+':id', prefix+':currency', prefix+':nbConnection', prefix+':interval',prefix+':created_at',prefix+':updated_at',prefix+':amount', prefix+':subscription_count:active',prefix+':subscription_count:inactive',prefix+':status', prefix+':name', prefix+':nbApp', prefix+':nbProvider', prefix+':responseDelay',prefix+':parent', prefix]
							[ 'srem', "pm:offers", name],
							[ 'srem', "pm:offers:#{status}", name],
							[ "hdel", "pm:offers:offers_id", id_offer ]
						]).exec (err) ->
							return cb err if err
							cb null, name
			(cb) => # TTC
				db.redis.mget "#{prefix_ttc}:id", "#{prefix_ttc}:status", (err, res) ->
					return callback err if err

					id_offer = res[0]
					status = res[1]

					paymill.offers.remove id_offer, (err, offer) ->
						#return callback err if err

						db.redis.multi([
							[ 'del', prefix_ttc+':id', prefix_ttc+':currency', prefix_ttc+':nbConnection', prefix_ttc+':interval',prefix_ttc+':created_at',prefix_ttc+':updated_at',prefix_ttc+':amount', prefix_ttc+':subscription_count:active',prefix_ttc+':subscription_count:inactive',prefix_ttc+':status', prefix_ttc+':name', prefix_ttc+':nbApp', prefix_ttc+':nbProvider', prefix_ttc+':responseDelay', prefix_ttc+':parent', prefix_ttc]
							[ 'srem', "pm:offers", name_ttc],
							[ 'srem', "pm:offers:#{status}", name_ttc],
							[ "hdel", "pm:offers:offers_id", id_offer ]
						]).exec (err) ->
							return cb err if err
							cb null, name_ttc
		], (err, res) ->
			return callback err if err
			return callback null, res

# getList of Offer
exports.getOffersList = (callback) ->
	prefix = "pm:offers"

	db.redis.smembers "#{prefix}", (err, offers) ->
		return callback err if err
		return callback null, [] if not offers.length

		cmds = []
		for p in offers
			cmds.push [ "get", "#{prefix}:#{p}:id"]
			cmds.push [ "get", "#{prefix}:#{p}:name"]
			cmds.push [ "get", "#{prefix}:#{p}:currency"]
			cmds.push [ "get", "#{prefix}:#{p}:interval"]
			cmds.push [ "get", "#{prefix}:#{p}:created_at"]
			cmds.push [ "get", "#{prefix}:#{p}:updated_at"]
			cmds.push [ "get", "#{prefix}:#{p}:amount"]
			cmds.push [ "get", "#{prefix}:#{p}:status"]
			cmds.push [ "get", "#{prefix}:#{p}:nbConnection"]
			cmds.push [ "get", "#{prefix}:#{p}:parent"]
			cmds.push [ "get", "#{prefix}:#{p}:nbApp"]
			cmds.push [ "get", "#{prefix}:#{p}:nbProvider"]
			cmds.push [ "get", "#{prefix}:#{p}:responseDelay"]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of offers
				res[i * 13 + 8] = if res[i * 13 + 8] is "*" then "unlimited" else res[i * 13 + 8]
				res[i * 13 + 10] = if res[i * 13 + 10] is "*" then "unlimited" else res[i * 13 + 10]
				res[i * 13 + 11] = if res[i * 13 + 11] is "*" then "unlimited" else res[i * 13 + 11]
				offers[i] = id:res[i * 13], name:res[i * 13 + 1], currency:res[i * 13 + 2], interval:res[i * 13 + 3], created_at:res[i * 13 + 4], updated_at:res[i * 13 + 5], amount:res[i * 13 + 6], status:res[i * 13 + 7], nbConnection:res[i * 13 + 8], parent: res[i * 13 + 9], nbApp: res[i * 13 + 10], nbProvider: res[i * 13 + 11], responseDelay: res[i * 13 + 12]
			return callback null, offers: offers

# update Status of an Offer
exports.updateStatus = (name, currentStatus, callback) ->
	newStatus = "private"
	if currentStatus == "private"
		newStatus = "public"

	prefix = "pm:offers"

	db.redis.multi([

		[ 'srem', "#{prefix}:#{currentStatus}", name ]
		[ 'sadd', "#{prefix}:#{newStatus}", name ]
		[ 'set', "#{prefix}:#{name}:status", newStatus ]

	]).exec (err, replies) ->
		return callback err if err
		return callback null, name


exports.getPublicOffers = (clientId, callback) ->
	prefix = "pm:offers"

	db.redis.smembers "#{prefix}:public", (err, offers) ->
		return callback err if err
		return callback null, [] if not offers.length

		cmds = []
		for offer_name in offers
			cmds.push [ "get", "#{prefix}:#{offer_name}:id"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:name"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:currency"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:interval"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:amount"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:nbConnection"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:nbApp"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:nbProvider"]
			cmds.push [ "get", "#{prefix}:#{offer_name}:responseDelay"]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of offers
				nbConnection = if res[i * 9 + 5] is "*" then "unlimited" else res[i * 9 + 5]
				nbApp = if res[i * 9 + 6] is "*" then "unlimited" else res[i * 9 + 6]
				nbProvider = if res[i * 9 + 7] is "*" then "unlimited" else res[i * 9 + 7]
				if res[i * 9 + 1]?
					offers[i] = id:res[i * 9], name:res[i * 9 + 1], currency:res[i * 9 + 2], interval:res[i * 9 + 3], amount:res[i * 9 + 4], nbConnection:nbConnection, nbApp:nbApp, nbProvider:nbProvider, responseDelay:res[i * 9 + 8]

			if clientId?
				PaymillClient = require '../server.payments/paymill_client'
				client = new PaymillClient()
				client.user_id = clientId.id
				client.getCurrentPlan (err, current_plan) ->
					return callback err if err
					return callback null, offers: offers, current_plan: current_plan
			else
				return callback null, offers: offers

exports.getOfferByName = (name, callback) ->
	return callback new check.Error "This plan does not exists" if not name?

	prefix = "pm:offers:#{name}"

	db.redis.mget [ "#{prefix}:id", "#{prefix}:name", "#{prefix}:amount", "#{prefix}:nbConnection", "#{prefix}:nbApp", "#{prefix}:nbProvider", "#{prefix}:responseDelay", "#{prefix}:status" ], (err, res) ->
		return callback err if err
		return callback new check.Error "This plan does not exists" if not res?
		nbConnection = if res[3] is "*" then "unlimited" else res[3]
		nbApp = if res[4] is "*" then "unlimited" else res[4]
		nbProvider = if res[5] is "*" then "unlimited" else res[5]
		return callback null, offer: res[0], name:res[1], amount:parseInt(res[2]) / 100, nbConnection:nbConnection, nbApp:nbApp, nbProvider:nbProvider, status:res[4]

exports.unsubscribe = (client, callback) ->
	return callback new restify.NotAuthorizedError if not client?

	db.redis.multi([

		[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{client.id}", "current_subscription"],
		[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{client.id}", "current_offer" ]

	]).exec (err, res) ->
		return callback err if err
		return callback new check.Error "An error occured, please contact support@oauth.io" if not res?

		PaymillSubscription = require '../server.payments/paymill_subscription'
		subscription = new PaymillSubscription
		subscription.id = res[0]
		subscription.user_id = client.id
		subscription.refund (error, result) ->
			PaymillBase.paymill.subscriptions.remove res[0], (err, subscription_updated) ->

				subscription_prefix = "#{PaymillBase.subscriptions_root_prefix}:#{client.id}:#{res[0]}"

				db.redis.multi([

						[ "hdel", "#{PaymillBase.subscriptions_root_prefix}:#{client.id}", "current_subscription" ],
						[ "hdel", "#{PaymillBase.subscriptions_root_prefix}:#{client.id}", "current_offer"],

						[ "del", "#{subscription_prefix}:id" ],
						[ "del", "#{subscription_prefix}:offer" ],
						[ "del", "#{subscription_prefix}:next_capture_at" ],
						[ "del", "#{subscription_prefix}:created_at" ],
						[ "del", "#{subscription_prefix}:updated_at" ],
						[ "del", "#{subscription_prefix}:canceled_at" ],
						[ "del", "#{subscription_prefix}:payment" ],
						[ "del", "#{subscription_prefix}:client" ],
						[ "del", "#{subscription_prefix}:notified" ]

					]).exec (err) =>
						return callback err if err

						shared.emit 'user.unsubscribe', client

						Payment.delCart client.id, (err, result) ->
							return err if err
							return callback null, subscription_updated