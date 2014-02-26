# oauthd
# http://oauth.io
#
# Copyright (c) 2013 Webshell
# For private use only.
#

{ db, check, config } = shared = require '../shared'

stripe = require('stripe')(config.stripe.secret)

async = require 'async'
restify = require 'restify'
countries = require './countries'

checkCouponPlan = (coupon, plan) ->
	return true if not coupon
	return false if coupon.length < 4
	plan_shortcuts =
		"st_": "startup"
		"gw_": "growth"
		"sc_": "scalability"
	plan_limit = plan_shortcuts[coupon.substr(0,3)]
	return false if plan_limit and plan.substr(0, plan_limit.length) != plan_limit
	return true

getCustomer = (id, callback) ->
	db.redis.get "u:#{id}:stripeid", (err, stripeid) ->
		return callback err if err
		return callback null, null if not stripeid
		stripe.customers.retrieve stripeid, callback

createCustomer = (data, callback) ->
	if not checkCouponPlan(data.coupon, data.plan)
		return callback new check.Error 'This code is not available for this plan'

	stripe.customers.create (
		card: data.token.id
		email: data.user.mail
		metadata: data.profile
		plan: data.plan
		coupon: data.coupon
		trial_end: Math.floor(new Date / 1000) + 15
	), (err, customer) ->
		return callback err if err
		db.redis.set "u:#{data.user.id}:stripeid", customer.id, callback

updateSubscription = (data, callback) ->
	if not checkCouponPlan(data.coupon, data.plan)
		return callback new check.Error 'This code is not available for this plan'

	stripe.customers.update data.stripeid,
		card: data.token.id
		email: data.user.mail
		metadata: data.profile

	stripe.customers.listSubscriptions data.stripeid, (err, subscriptions) ->
		return callback err if err
		opts =
			plan: data.plan
			coupon: data.coupon
		if subscriptions.data?[0]
			stripe.customers.updateSubscription data.stripeid, subscriptions.data[0].id, opts, callback
		else
			stripe.customers.createSubscription data.stripeid, opts, callback


fillInfos = (data_in, name, callback) ->
	data = {}
	data[name] = data_in
	return callback null, data if not data_in.customer
	stripe.customers.retrieve data_in.customer, (err, customer) ->
		return callback err if err
		return callback() if not customer or customer.deleted
		data.customer = customer
		db.users.get customer.metadata.id, (err, user) ->
			return callback err if err
			data.user = user
			return callback null, data

exports.hooks =
	'invoice.payment_succeeded': (invoice, callback) ->
		fillInfos invoice, 'invoice', (err, data) ->
			return callback err if err
			return callback() if not data
			shared.emit 'user.pay', data
			callback()

	'invoice.payment_failed': (invoice, callback) ->
		fillInfos invoice, 'invoice', (err, data) ->
			return callback err if err
			return callback() if not data
			shared.emit 'user.pay.failed', data
			callback()

	'customer.subscription.created': (subscription, callback) ->
		fillInfos subscription, 'subscription', (err, data) ->
			return callback err if err
			return callback() if not data
			shared.emit 'user.subscribe', data
			db.redis.set "u:#{data.user.profile.id}:current_plan", subscription.plan.id, callback

	'customer.subscription.updated': (subscription, callback) ->
		fillInfos subscription, 'subscription', (err, data) ->
			return callback err if err
			return callback() if not data
			shared.emit 'user.subscribe', data
			db.redis.set "u:#{data.user.profile.id}:current_plan", subscription.plan.id, callback

	'customer.subscription.deleted': (subscription, callback) ->
		fillInfos subscription, 'subscription', (err, data) ->
			return callback err if err
			return callback() if not data
			shared.emit 'user.unsubscribe', data
			db.redis.del "u:#{data.user.profile.id}:current_plan"
			callback()


exports.subscribe = check profile:'object', coupon:['string','none'], token:'object', plan:'string', 'object', (data, user, callback) ->
	if data.profile.country_code == 'FR'
		data.plan += '_fr'
	data.profile.id = user.id
	data.profile.country = countries[data.profile.country_code || "US"]
	delete data.profile.country_code
	data.user = user
	async.waterfall [
		(cb) -> getCustomer data.profile.id, cb
		(customer, cb) ->
			if customer and not customer.deleted
				data.stripeid = customer.id
				updateSubscription data, cb
			else
				createCustomer data, cb
		(res, cb) ->
			db.redis.set "u:#{user.id}:current_plan", data.plan, cb
	], (err) ->
		return callback err if err
		callback null

exports.unsubscribe = (user, callback) ->
	getCustomer user.id, (err, customer) ->
		return callback err if err or not customer
		stripe.customers.listSubscriptions customer.id, (err, subscriptions) ->
			return callback err if err
			return callback() if not subscriptions.data?[0]
			stripe.customers.cancelSubscription customer.id, subscriptions.data[0].id, (err, confirmation) ->
				return callback err if err
				db.redis.del "u:#{user.id}:current_plan"
				callback()

exports.getCoupon = check coupon:'string', plan:'string', (data, callback) ->
	stripe.coupons.retrieve data.coupon, (err, coupon) ->
		return callback err if err
		return callback new check.Error 'Invalid coupon' if not coupon.valid
		if not checkCouponPlan(data.coupon, data.plan)
			return callback new check.Error 'This code is not available for this plan'
		callback null, amount_off:coupon.amount_off, percent_off:coupon.percent_off, duration:coupon.duration, duration_in_months:coupon.duration_in_months