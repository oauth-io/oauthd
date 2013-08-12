# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#
#

async = require 'async'
{ db, check, config } = shared = require '../shared'
paymill = require('paymill-node')(config.paymill.secret_key)

# create an Offer
exports.createOffer = (amount, name, currency, interval, nbConnection,status, callback) ->


	console.log("create Offer "+ name + " of " + amount + " " + currency + " during " + interval + " up to " + nbConnection + " in " + status);
	prefix = "pm:offers"
	name = name.toLowerCase()

	db.redis.sismember [ "#{prefix}", name ], (err, res) ->
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
						"#{prefix}:#{name}:nbConnection", nbConnection],

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

	return callback new check.Error if not name?

	prefix = "pm:offers:#{name}"

	db.redis.mget [ "#{prefix}:id", "#{prefix}:name", "#{prefix}:amount", "#{prefix}:nbConnection" ], (err, res) ->
		return callback err if err
		return callback null, offer: res[0], name:res[1], amount:parseInt(res[2]) / 100, nbConnection:res[3]

# update an Offer
#exports.updateOffer = (amount, name, currency, interval, callback) ->
#
#	console.log("update Offer "+ name + " of " + amount + " " + currency + " during " + interval);
#	prefix = "pm:offers"
#
#	db.redis.sismember [ "#{prefix}:#{name}", 1 ], (err, res) ->
#		return callback err if err
#		return callback new check.Error "Sorry but you have already added " + name.toUpperCase() if res == 1
#
#		paymill.offers.update
#			amount: amount
#			currency: currency
#			interval: interval
#			name: name
#		,(err, offer) ->
#			return callback err if err
#
#			console.log "offer id " + offer.data.id
#
#			offer.data.name = name;
#			console.log "offer name " + offer.data.name
#
#			db.redis.multi([
#				[ 'sadd', "#{prefix}", name ],
#				[ 'sadd', "#{prefix}:#{name}", 1],
#				[ 'mset', "#{prefix}:#{name}:id", offer.data.id,
#						"#{prefix}:#{name}:currency", offer.data.currency,
#						"#{prefix}:#{name}:interval", offer.data.interval,
#						"#{prefix}:#{name}:created_at", offer.data.created_at,
#						"#{prefix}:#{name}:updated_at", offer.data.updated_at,
#						"#{prefix}:#{name}:amount", offer.data.amount,
#					  	"#{prefix}:#{name}:subscription_count:active", offer.data.subscription_count.active,
#					  	"#{prefix}:#{name}:subscription_count:inactive", offer.data.subscription_count.inactive
#				 ]
#				]).exec (err) ->
#					return callback err if err
#					return callback null, offer.data
