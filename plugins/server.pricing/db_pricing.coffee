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
exports.createOffer = (amount, name, currency, interval, status, callback) ->

	console.log("create Offer "+ name + " of " + amount + " " + currency + " during " + interval + " in " + status);
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

			offer.data.name = name;
			offer.data.status = status;

			db.redis.multi([
				[ 'sadd', "#{prefix}", name ],
				[ 'sadd', "#{prefix}:#{name}", 1],
				[ 'mset', "#{prefix}:#{name}:id", offer.data.id,
						"#{prefix}:#{name}:currency", offer.data.currency,
						"#{prefix}:#{name}:interval", offer.data.interval,
						"#{prefix}:#{name}:created_at", offer.data.created_at,
						"#{prefix}:#{name}:updated_at", offer.data.updated_at,
						"#{prefix}:#{name}:amount", offer.data.amount,
						"#{prefix}:#{name}:status", status,					  	"#{prefix}:#{name}:subscription_count:active", offer.data.subscription_count.active,
					  	"#{prefix}:#{name}:subscription_count:inactive", offer.data.subscription_count.inactive
				 ]
				[ 'sadd', "#{prefix}:#{status}", name ],
				[ 'mset', "#{prefix}:#{status}:#{name}:id", offer.data.id,
						"#{prefix}:#{status}:#{name}:amount", offer.data.amount,
						"#{prefix}:#{status}:#{name}:interval", offer.data.interval
				 ]
				]).exec (err) ->
					return callback err if err
					return callback null, offer.data

# delete an Offer
exports.removeOffer = (name, callback) ->
	prefix = 'pm:offers:' + name
	db.redis.sismember ['pm:offers' , name], (err, res) ->
		return callback err if err

		db.redis.multi([
			[ 'get', "#{prefix}:id"],
			[ 'get', "#{prefix}:status"],
		]).exec (err, replies) ->
			return callback err if err

			id_offer = replies[0]

			paymill.offers.remove id_offer, (err, offer) ->
  				return callback err if err

			prefix2 = 'pm:offers:' + replies[1]
			prefix3 = prefix2 + ':' + name

			db.redis.multi([
				[ 'del', prefix+':id', prefix+':currency', prefix+':interval',prefix+':created_at',prefix+':updated_at',prefix+':amount', prefix+':subscription_count:active',prefix+':subscription_count:inactive',prefix+':status',prefix, prefix3+':id', prefix3+':currency', prefix3+':amount',prefix3+':interval', prefix3]
				[ 'srem', 'pm:offers', name],
				[ 'srem', prefix2, name],
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
			cmds.push [ "get", "#{prefix}:#{p}:status"]
			cmds.push [ "get", "#{prefix}:#{p}:subscription_count:active"]
			cmds.push [ "get", "#{prefix}:#{p}:subscription_count:inactive"]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err

			for i of offers
				offers[i] = id:res[i * 9], currency:res[i * 9 + 1], interval:res[i * 9 + 2], created_at:res[i * 9 + 3], updated_at:res[i * 9 + 4], amount:res[i * 9 + 5], status:res[i * 9 + 6], subscription_count:active:res[i * 9 + 7], subscription_count:inactive:res[i * 9 + 8]
				offers[i].name = tmpName[i]

			return callback null, offers

# update Status of an Offer
exports.updateStatus = (name, currentStatus, callback) ->

	newStatus = "private"
	if currentStatus == "private"
		newStatus = "public"

	prefix = "pm:offers:" + name
	prefixStatus = "pm:offers:" + currentStatus + ":" + name
	prefixNewStatus = "pm:offers:" + newStatus
	db.redis.multi([
		[ 'get', "#{prefix}:id"],
		[ 'get', "#{prefix}:amount"],
		[ 'get', "#{prefix}:interval"],
	]).exec (err, replies) ->
		return callback err if err

		offer = {}
		offer.id = replies[0]
		offer.amount = replies[1]
		offer.interval = replies[2]

		db.redis.multi([
			[ 'del', "#{prefixStatus}:id", prefixStatus+':interval', prefixStatus+':amount', prefixStatus]
			[ 'set', "#{prefix}:status", newStatus],
			[ 'sadd', "#{prefixNewStatus}", name ],
			[ 'mset', "#{prefixNewStatus}:#{name}:id", offer.id,
					"#{prefixNewStatus}:#{name}:amount", offer.amount,
					"#{prefixNewStatus}:#{name}:interval", offer.interval
			]
		]).exec (err, replies) ->
			return callback err if err
			return callback null, name


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
