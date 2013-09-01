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

# create an Offer
exports.createOffer = (data, callback) ->


	console.log("create Offer "+ data.name + " of " + data.amount + " " + data.currency + " during " + data.interval + " up to " + data.nbConnection + " in " + data.status);
	prefix = "pm:offers"
	name = data.name.toLowerCase()
	status = data.status

	db.redis.sismember [ "#{prefix}", name ], (err, res) ->
		return callback err if err
		return callback new check.Error "Sorry but you have already added " + name.toUpperCase() if res == 1

		paymill.offers.create
			amount: data.amount
			currency: data.currency
			interval: data.interval
			name: name
		,(err, offer) ->
			return callback err if err

			console.log "offer id " + offer.data.id

			offer.data.name = name;
			offer.data.status = status;

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
						"#{prefix}:#{name}:nbConnection", data.nbConnection],

				[ "hset", "#{prefix}:offers_id", offer.data.id, name ]

			]).exec (err) ->
				return callback err if err
				return callback null, offer.data

# delete an Offer
exports.removeOffer = (name, callback) ->

	prefix = 'pm:offers:' + name
	name = name.toLowerCase()

	db.redis.sismember ['pm:offers' , name], (err, res) ->
		return callback err if err
		return callback new check.Error "#{name.toUpperCase()} not found !" if not res

		db.redis.mget "#{prefix}:id", "#{prefix}:status", (err, res) ->
			return callback err if err

			id_offer = res[0]
			status = res[1]

			paymill.offers.remove id_offer, (err, offer) ->
				return callback err if err

				db.redis.multi([
					[ 'del', prefix+':id', prefix+':currency', prefix+':nbConnection', prefix+':interval',prefix+':created_at',prefix+':updated_at',prefix+':amount', prefix+':subscription_count:active',prefix+':subscription_count:inactive',prefix+':status', prefix]
					[ 'srem', "pm:offers", name],
					[ 'srem', "pm:offers:#{status}", name],
					[ "hdel", "pm:offers:offers_id", id_offer ]
				]).exec (err) ->
					return callback err if err
					return callback null, name

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

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of offers
				offers[i] = id:res[i * 9], name:res[i * 9 + 1], currency:res[i * 9 + 2], interval:res[i * 9 + 3], created_at:res[i * 9 + 4], updated_at:res[i * 9 + 5], amount:res[i * 9 + 6], status:res[i * 9 + 7], nbConnection:res[i * 9 + 8]

			return callback null, offers

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


exports.getPublicOffers = (callback) ->

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

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of offers
				offers[i] = id:res[i * 6], name:res[i * 6 + 1], currency:res[i * 6 + 2], interval:res[i * 6 + 3].toLowerCase() , amount:res[i * 6 + 4], nbConnection:res[i * 6 + 5]

			return callback null, offers

exports.getOfferByName = (name, callback) ->

	return callback new check.Error "This plan does not exists" if not name?

	prefix = "pm:offers:#{name}"

	db.redis.mget [ "#{prefix}:id", "#{prefix}:name", "#{prefix}:amount", "#{prefix}:nbConnection", "#{prefix}:status" ], (err, res) ->
		return callback err if err
		return callback new check.Error "This plan does not exists" if not res?
		return callback null, offer: res[0], name:res[1], amount:parseInt(res[2]) / 100, nbConnection:res[3], status:res[4]

exports.unsubscribe = (client, callback) ->
	return callback new restify.NotAuthorizedError if not client?

	db.redis.multi([

		[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{client.id}", "current_subscription"],
		[ "hget", "#{PaymillBase.subscriptions_root_prefix}:#{client.id}", "current_offer" ]

	]).exec (err, res) =>
		return callback err if err
		return callback new check.Error "An error occured, please contact support@oauth.io" if not res?

		PaymillBase.paymill.subscriptions.remove res[0], (err, subscription_updated) =>

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
					return callback null, subscription_updated
