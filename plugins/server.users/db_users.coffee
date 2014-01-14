# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

async = require 'async'
Mailer = require '../../lib/mailer'

{config,check,db} = shared = require '../shared'

# register a new user
exports.register = check mail:check.format.mail, (data, callback) ->
	date_inscr = (new Date).getTime()
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'This email already exists !' if iduser
		db.redis.incr 'u:i', (err, val) ->
			return callback err if err
			prefix = 'u:' + val + ':'
			key = db.generateUid()
			db.redis.multi([
				[ 'mset', prefix+'mail', data.mail,
					prefix+'key', key,
					prefix+'validated', 0,
					prefix+'date_inscr', date_inscr ],
				[ 'hset', 'u:mails', data.mail, val ]
			]).exec (err, res) ->
				return callback err if err
				user = id:val, mail:data.mail, date_inscr:date_inscr, key:key
				shared.emit 'user.register', user
				return callback null, user

exports.updateBilling = (req, callback) ->
	profile = req.body.profile
	billing = req.body.billing
	user_id = req.user.id
	profile_prefix = "u:#{user_id}:"
	billing_prefix = "u:#{user_id}:billing:"
	cmds = []

	if profile?
		cmds.push [ 'mset', profile_prefix + 'mail', db.emptyStrIfNull(profile.mail),
			profile_prefix + 'name', db.emptyStrIfNull(profile.name),
			profile_prefix + 'company', db.emptyStrIfNull(profile.company),
			profile_prefix + 'website', db.emptyStrIfNull(profile.website),
			profile_prefix + 'addr_one', db.emptyStrIfNull(profile.addr_one),
			profile_prefix + 'addr_second', db.emptyStrIfNull(profile.addr_second),
			profile_prefix + 'city', db.emptyStrIfNull(profile.city),
			profile_prefix + 'zipcode', db.emptyStrIfNull(profile.zipcode),
			profile_prefix + 'country_code', db.emptyStrIfNull(profile.country_code),
			profile_prefix + 'country', db.emptyStrIfNull(profile.country),
			profile_prefix + 'state', db.emptyStrIfNull(profile.state),
			profile_prefix + 'phone', db.emptyStrIfNull(profile.phone),
			profile_prefix + 'type', profile.type,
			profile_prefix + 'vat_number', db.emptyStrIfNull(profile.vat_number),
			profile_prefix + 'use_profile_for_billing', profile.use_profile_for_billing ]

	if billing?
		Payment = require '../server.payments/db_payments'
		Payment.getCart user_id, (err, cart) ->
			return callback err if err

			cart_prefix = "pm:carts:#{user_id}:"
			total = cart.unit_price * cart.quantity
			if billing.country_code == "FR"
				tva = 0.20
				total_tva = Math.floor((total * tva) * 100) / 100
				total += total_tva
				total = Math.floor(total * 100) / 100
			else
				tva = 0
				total_tva = 0

			cmds.push [ 'mset', billing_prefix + 'mail', db.emptyStrIfNull(billing.mail),
				billing_prefix + 'name', db.emptyStrIfNull(billing.name),
				billing_prefix + 'company', db.emptyStrIfNull(billing.company),
				billing_prefix + 'website', db.emptyStrIfNull(billing.website),
				billing_prefix + 'addr_one', db.emptyStrIfNull(billing.addr_one),
				billing_prefix + 'addr_second', db.emptyStrIfNull(billing.addr_second),
				billing_prefix + 'city', db.emptyStrIfNull(billing.city),
				billing_prefix + 'zipcode', db.emptyStrIfNull(billing.zipcode),
				billing_prefix + 'country_code', db.emptyStrIfNull(billing.country_code),
				billing_prefix + 'country', db.emptyStrIfNull(billing.country),
				billing_prefix + 'state', db.emptyStrIfNull(billing.state),
				billing_prefix + 'phone', db.emptyStrIfNull(billing.phone),
				billing_prefix + 'type', billing.type,
				billing_prefix + 'vat_number', db.emptyStrIfNull(billing.vat_number),

				cart_prefix + 'VAT_percent', tva * 100,
				cart_prefix + 'VAT', total_tva,
				cart_prefix + 'total', total ]

			db.redis.multi(cmds).exec (err) ->
				return callback err if err
				return callback null

exports.cancelUpdateEmail = (req, callback) ->
	user_id = req.user.id
	prefix = "u:#{user_id}:"
	db.redis.mset [ prefix + 'mail_changed', ''], (err, res) =>
		return callback null, {cancelled: true}

exports.updateEmail = (req, callback) ->
	email = req.body.email
	user_id = req.user.id
	prefix = "u:#{user_id}:"
	old_email = null

	db.redis.mget [ prefix + 'mail'], (err, res) =>
		old_email = res[0]

		db.redis.hget 'u:mails', email, (err, id) ->
			return callback err if err
			return callback new check.Error "Your email has not changed" if old_email == email
			return callback new check.Error "#{email} already exists" if id

			validation_key = db.generateUid()
			db.redis.mset [
				prefix + 'mail_changed', email,
				prefix + 'key', validation_key
			], (err) ->
				return callback err if err

				#send mail with key
				options =
					to:
						email: email
					from:
						name: 'OAuth.io'
						email: 'team@oauth.io'
					subject: 'OAuth.io - You email address has been updated'
					body: "Hello,\n\n
In order to validate your new email address, please click the following link: https://" + config.url.host + "/validate/" + user_id + "/" + validation_key + "\n

--\n
OAuth.io Team"
				mailer = new Mailer options
				mailer.send (err, result) ->
					return callback err if err
					user = id:user_id, mail:email
					return callback null, user

# update user infos
exports.updateAccount = (req, callback) ->
	data = req.body.profile
	user_id = req.user.id
	prefix = "u:#{user_id}:"

	db.redis.mset [
		prefix + 'name', data.name,
		prefix + 'location', data.location,
		prefix + 'company', data.company,
		prefix + 'website', data.website,
		# prefix + 'addr_one', data.addr_one,
		# prefix + 'addr_second', data.addr_second,
		# prefix + 'city', data.city,
		# prefix + 'zipcode', data.zipcode,
		# prefix + 'country', data.country,
		# prefix + 'country_code', data.country_code,
		# prefix + 'state', data.state,
		# prefix + 'phone', data.phone
	], (err) ->
		return callback err if err
		user = id:user_id, name:data.name, company:data.company, website:data.website, location:data.location
		return callback null, user


exports.isValidable = (data, callback) ->
	key = data.key
	iduser = data.id
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix+'mail', prefix+'key', prefix+'validated', prefix+'pass', prefix+'mail_changed'], (err, replies) ->
		return callback err if err
		return callback null, is_validable: false if replies[3]? and not replies[4]? or not replies[3] and replies[4]?
		return callback null, is_validable: false if replies[1] != key

		if replies[3]? and replies[4]? # change email
			return callback null, is_validable: false if replies[4].length == 0
			db.redis.multi([
				[ 'hdel', 'u:mails', replies[0] ],
				[ 'hset', 'u:mails', replies[4], iduser ],
				[ 'mset', prefix+'validated', 1,
					prefix+'mail', replies[4],
					prefix+'mail_changed', '',
					prefix+'key', '' ]
			]).exec (err, res) ->
				return callback err  if err
				return callback null, is_updated: true, mail: replies[4], id: iduser
		else # validable but no password
			return callback null, is_validable: false if replies[2] == '1'
			return callback null, is_validable: true, mail: replies[0], id: iduser

# validate user mail
exports.validate = check pass:/^.{6,}$/, (data, callback) ->
	dynsalt = Math.floor(Math.random()*9999999)
	pass = db.generateHash data.pass + dynsalt
	exports.isValidable {
		id: data.id,
		key: data.key
	}, (err, res) ->
		return callback new check.Error "This page does not exists." if not res.is_validable or err
		prefix = 'u:' + res.id + ':'
		key = db.generateUid()
		db.redis.mset [
			prefix+'validated', 1,
			prefix+'pass', pass,
			prefix+'salt', dynsalt,
			prefix+'key', key,
			prefix+'date_validate', (new Date).getTime()
		], (err) ->
			return err if err
			shared.emit 'user.validate', id: res.id, mail: res.mail, key:key
			return callback null, mail: res.mail, id: res.id

# lost password
exports.lostPassword = check mail:check.format.mail, (data, callback) ->

	mail = data.mail
	db.redis.hget 'u:mails', data.mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error "This email isn't registered" if not iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'key_pass', prefix+'validated'], (err, replies) ->
			return callback new check.Error "This email is not validated yet. Patience... :)" if replies[2] == '0'
			# ok email validated  (contain password)
			key = replies[1]
			if not key
				dynsalt = Math.floor(Math.random() * 9999999)
				key = db.generateHash(dynsalt).replace(/\=/g, '').replace(/\+/g, '').replace(/\//g, '')

				# set new key
				db.redis.mset [
					prefix + 'key_pass', key
				], (err, res) ->
					return err if err

			#send mail with key
			options =
					to:
						email: replies[0]
					from:
						name: 'OAuth.io'
						email: 'team@oauth.io'
					subject: 'OAuth.io - Lost Password'
					body: "Hello,\n\n
Did you forget your password ?\n
To change it, please use the follow link to reset your password.\n\n

#{config.host_url}/resetpassword/#{iduser}/#{key}\n\n

--\n
OAuth.io Team"
				mailer = new Mailer options
				mailer.send (error, result) ->
					return callback error if error
					return callback null

exports.isValidKey = (data, callback) ->
	key = data.key
	iduser = data.id
	prefix = 'u:' + iduser + ':'
	db.redis.mget [prefix + 'mail', prefix + 'key_pass'], (err, replies) ->
		return callback err if err

		if replies[1].replace(/\=/g, '').replace(/\+/g, '') != key
			return callback null, isValidKey: false

		return callback null, isValidKey: true, email: replies[0], id: iduser

exports.resetPassword = check pass:/^.{6,}$/, (data, callback) ->
	exports.isValidKey {
		id: data.id,
		key: data.key
	}, (err, res) ->
		return callback err if err
		return callback new check.Error "This page does not exists." if not res.isValidKey

		prefix = 'u:' + res.id + ':'
		dynsalt = Math.floor(Math.random() * 9999999)
		pass = db.generateHash data.pass + dynsalt

		db.redis.mset [
			prefix + 'pass', pass,
			prefix + 'salt', dynsalt,
			prefix + 'key_pass', '', # clear
			prefix + 'validated', 1
		], (err) ->
			return callback err if err
			return callback null, email:res.email, id:res.id

# change password
exports.updatePassword = (req, callback) ->
	data = req.body
	iduser = req.user.id
	new_pass = data.new_password
	pass = data.current_password
	return callback new check.Error 'Your password must have a least 6 characters' if pass? and pass.length < 6

	prefix = 'u:' + iduser + ':'
	db.redis.mget [
		prefix+'pass',
		prefix+'salt',
		prefix+'mail',
		prefix+'date_inscr',
		prefix+'validated'], (err, replies) ->
			return callback err if err
			calcpass = db.generateHash pass + replies[1]
			return callback new check.Error 'Bad password' if replies[0] != calcpass || replies[4] != "1"

			#set new_pass to prefix_pass / refresh salt
			dynsalt = Math.floor(Math.random() * 9999999)
			pass = db.generateHash new_pass + dynsalt
			db.redis.mset [
				prefix+'pass', pass,
				prefix+'salt', dynsalt
			], (err) ->
				return callback err  if err
				return callback null, updated: true

# get a user by his id
exports.get = check 'int', (iduser, callback) ->
	Clients = require '../server.payments/paymill_client'
	client = new Clients()
	client.user_id = iduser

	prefix = 'u:' + iduser + ':'
	db.redis.mget [ prefix + 'mail',
		prefix + 'date_inscr',
		prefix + 'name',
		prefix + 'location',
		prefix + 'company',
		prefix + 'website',
		prefix + 'addr_one',
		prefix + 'addr_second',
		prefix + 'company',
		prefix + 'country_code',
		prefix + 'name',
		prefix + 'phone',
		prefix + 'type',
		prefix + 'zipcode',
		prefix + 'city',
		prefix + 'vat_number',
		prefix + 'use_profile_for_billing',
		prefix + 'state',
		prefix + 'country',
		prefix + 'mail_changed' ]
	, (err, replies) ->
		return callback err if err
		profile =
			id:iduser,
			mail:replies[0],
			date_inscr:replies[1],
			name: replies[2],
			location: replies[3],
			company: replies[4],
			website: replies[5],
			addr_one: replies[6],
			addr_second: replies[7],
			company: replies[8],
			country_code: replies[9],
			name: replies[10],
			phone: replies[11],
			type: replies[12],
			zipcode: replies[13],
			city : replies[14],
			vat_number: replies[15],
			use_profile_for_billing: replies[16] == "true" ? true : false
			state : replies[17],
			country : replies[18],
			mail_changed: replies[19]

		for field of profile
			profile[field] = '' if profile[field] == 'undefined'

		exports.getPlan iduser, (err, plan) ->
			return callback err if err
			exports.getBilling iduser, (err, billing) ->
				return callback err if err
				return callback null, profile: profile, plan: plan, billing: billing

# get user billing
exports.getBilling = check 'int', (iduser, callback) ->

	prefix_billing = 'u:' + iduser + ':billing:'
	db.redis.mget [ prefix_billing + 'addr_one',
		prefix_billing + 'addr_second',
		prefix_billing + 'city',
		prefix_billing + 'company',
		prefix_billing + 'country_code',
		prefix_billing + 'mail',
		prefix_billing + 'name',
		prefix_billing + 'phone',
		prefix_billing + 'state',
		prefix_billing + 'type',
		prefix_billing + 'website',
		prefix_billing + 'zipcode',
		prefix_billing + 'vat',
		prefix_billing + 'country' ]
	, (err, replies) ->
		return callback err if err
		billing =
		{
			addr_one:  replies[0],
			addr_second:  replies[1],
			city: replies[2],
			company: replies[3],
			country_code: replies[4],
			mail: replies[5],
			name: replies[6],
			phone: replies[7],
			state: replies[8],
			type: replies[9],
			website: replies[10],
			zipcode: replies[11],
			vat: replies[12],
			country: replies[13]
		}
		return callback null, billing

# delete a user account
exports.remove = check 'int', (iduser, callback) ->
	prefix = 'u:' + iduser + ':'
	db.redis.get prefix+'mail', (err, mail) ->
		return callback err if err
		return callback new check.Error 'Unknown user' unless mail
		exports.getApps iduser, (err, appkeys) ->
			tasks = []
			for key in appkeys
				do (key) ->
					tasks.push (cb) -> db.apps.remove key, cb
			async.series tasks, (err) ->
				return callback err if err

				db.redis.multi([
					[ 'hdel', 'u:mails', mail ]
					[ 'del', prefix+'mail', prefix+'pass', prefix+'salt', prefix+'validated', prefix+'key'
							, prefix+'apps', prefix+'date_inscr' ]
				]).exec (err, replies) ->
					return callback err if err
					shared.emit 'user.remove', mail:mail
					callback()

# get a user by his mail
exports.getByMail = check check.format.mail, (mail, callback) ->
	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' unless iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [prefix+'mail', prefix+'date_inscr'], (err, replies) ->
			return callback err if err
			return callback null, id:iduser, mail:replies[0], date_inscr:replies[1]

# get apps ids owned by a user
exports.getApps = check 'int', (iduser, callback) ->
	db.redis.smembers 'u:' + iduser + ':apps', (err, apps) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' if not apps
		return callback null, [] if not apps.length
		keys = ('a:' + app + ':key' for app in apps)
		db.redis.mget keys, (err, appkeys) ->
			return callback err if err
			return callback null, appkeys

exports.getPlan = check 'int', (iduser, callback) ->
	db.redis.hget ["pm:subscriptions:#{iduser}", "current_offer"], (err, offer_id) ->
		return callback err if err
		return callback null if not offer_id?
		db.redis.hget ["pm:offers:offers_id", offer_id], (err, offer) ->
			return callback err if err
			prefix = "pm:offers:#{offer}"
			db.redis.mget ["#{prefix}:name", "#{prefix}:nbConnection", "#{prefix}:nbApp", "#{prefix}:nbProvider", "#{prefix}:responseDelay", "#{prefix}:parent"], (err, replies) ->
				return callback err if err

				replies[0] = replies[0].substr 0, replies[0].length - 2  if replies[0].substr(replies[0].length - 2, 2) is 'fr'
				replies[1] = if replies[1] == "*" then "unlimited" else replies[1]
				replies[2] = if replies[2] == "*" then "unlimited" else replies[2]
				replies[3] = if replies[3] == "*" then "unlimited" else replies[3]

				return callback null, name:replies[0], nbUsers:replies[1], nbApp:replies[2], nbProvider:replies[3], responseDelay:replies[4], parent: replies[5]

exports.getAllSubscriptions = check 'int', (iduser, callback) ->
	Clients = require '../server.payments/paymill_client'
	client = new Clients()
	client.user_id = iduser
	client.getSubscriptions (err, subscriptions) ->
	 	return callback err if err
	 	return callback null, subscriptions:subscriptions

# is an app owned by a user
exports.hasApp = check 'int', check.format.key, (iduser, key, callback) ->
	db.apps.get key, (err, app) ->
		return callback err if err
		db.redis.sismember 'u:' + iduser + ':apps', app.id, callback

# check if mail & pass match
exports.login = check check.format.mail, 'string', (mail, pass, callback) ->
	db.redis.hget 'u:mails', mail, (err, iduser) ->
		return callback err if err
		return callback new check.Error 'Unknown mail' unless iduser
		prefix = 'u:' + iduser + ':'
		db.redis.mget [
			prefix+'pass',
			prefix+'salt',
			prefix+'mail',
			prefix+'date_inscr',
			prefix+'validated'], (err, replies) ->
				return callback err if err
				calcpass = db.generateHash pass + replies[1]
				return callback new check.Error 'Bad password' if replies[0] != calcpass || replies[4] != "1"
				return callback null, id:iduser, mail:replies[2], date_inscr:replies[3]

exports.updateProviders = check 'int', (iduser, callback) ->
	exports.getApps iduser, (e, apps) ->
		return callback e if e
		cmds = []
		providers = {}
		for app in apps
			do (app) ->
				cmds.push (callback) ->
					db.apps.getKeysets app, (e, keysets) ->
						#return callback e if e
						return callback() if e # skip crashed apps
						providers[keyset] = true for keyset in keysets
						callback()
		async.parallel cmds, (e,r) ->
			return callback e if e
			pkey = 'u:' + iduser + ':providers'
			providers = Object.keys(providers)
			providers.unshift 'sadd', pkey
			multicmds = [['del', pkey]]
			multicmds.push providers if providers.length > 2
			db.redis.multi(multicmds).exec (e,r) ->
				return callback e if e
				callback null, providers.length

exports.updateConnections = check 'int', ['int','number'], (iduser, date, callback) ->
	setStat = (sum) ->
		db.redis.set "u:#{iduser}:nb_auth:#{year}-#{month+1}", sum, (e, r) ->
			return callback e if e
			shared.emit 'user.update_nbauth', id:iduser, "#{year}-#{month+1}", sum
			callback()

	date = new Date date
	year = date.getFullYear()
	month = date.getMonth()
	exports.getApps iduser, (e, keys) ->
		return callback e if e
		return setStat 0 if not keys or not keys.length
		stkeys = ("st:co:a:#{key}:m:#{year}-#{month+1}" for key in keys)
		db.redis.mget stkeys, (e,stats) ->
			return callback e if e
			sum = 0
			for st in stats
				sum += st-0 if st
			setStat sum

shared.on 'connect.auth', (data) ->
	db.apps.getOwner data.key, (e, user) ->
		return if e
		date = new Date
		year = date.getFullYear()
		month = date.getMonth()
		db.redis.incr "u:#{user.id}:nb_auth:#{year}-#{month+1}", (e, nb) ->
			return if e
			shared.emit 'user.update_nbauth', user, "#{year}-#{month+1}", nb

shared.on 'connect.auth.new_uid', (data) ->
	db.apps.getOwner data.key, (e, user) ->
		return if e
		date = new Date
		year = date.getFullYear()
		month = date.getMonth()
		db.redis.incr "u:#{user.id}:nb_uid:#{year}-#{month+1}", (e, nb) ->
			return if e
			shared.emit 'user.update_nbuid', user, "#{year}-#{month+1}", nb

shared.on 'connect.auth.new_mid', (data) ->
	db.apps.getOwner data.key, (e, user) ->
		return if e
		date = new Date
		year = date.getFullYear()
		month = date.getMonth()
		db.redis.incr "u:#{user.id}:nb_mid:#{year}-#{month+1}", (e, nb) ->
			return if e
			shared.emit 'user.update_nbmid', user, "#{year}-#{month+1}", nb

## Event: add app to user when created
shared.on 'app.create', (req, app) ->
	if req.user?.id
		db.redis.sadd 'u:' + req.user.id + ':apps', app.id
		db.redis.scard 'u:' + req.user.id + ':apps', (e, nbapps) ->
			shared.emit 'user.update_nbapps', req.user, nbapps


## Event: remove app from user when deleted
shared.on 'app.remove', (req, app) ->
	if req.user?.id
		db.redis.srem 'u:' + req.user.id + ':apps', app.id
		db.redis.scard 'u:' + req.user.id + ':apps', (e, nbapps) ->
			shared.emit 'user.update_nbapps', req.user, nbapps

updateProviders_byapp = (data) ->
	db.apps.getOwner data.app, (e, user) ->
		return if e
		exports.updateProviders user.id, (e, nb) ->
			return if e
			shared.emit 'user.update_nbproviders', user, nb


shared.on 'app.remkeyset', updateProviders_byapp
shared.on 'app.addkeyset', updateProviders_byapp