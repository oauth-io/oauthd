# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public Affero License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

crypto = require 'crypto'
restify = require 'restify'
restifyOAuth2 = require 'restify-oauth2-oauthd'

module.exports = (env) ->

	auth = {}

	_config =
		expire: 3600*5

	# register the adm passphrase (first time)
	db_register = env.utilities.check name:/^.{3,42}$/, pass:/^.{6,42}$/, (data, callback) ->
		env.data.redis.get 'adm:pass', (e,r) ->
			return callback new env.utilities.check.Error 'Unable to register' if e or r
			dynsalt = Math.floor(Math.random()*9999999)
			pass = env.data.generateHash data.pass + dynsalt
			env.data.redis.mset 'adm:salt', dynsalt, 'adm:pass', pass, 'adm:name', data.name, (err, res) ->
				return callback err if err
				callback()

	# checks if passphrase match
	db_login = env.utilities.check name:/^.{3,42}$/, pass:/^.{6,42}$/, (data, callback) ->
		env.data.redis.mget [
			'adm:pass',
			'adm:name',
			'adm:salt'], (err, replies) ->
				return callback err if err
				return callback null, false if not replies[1]
				calcpass = env.data.generateHash data.pass + replies[2]
				return callback new env.utilities.check.Error "Invalid email or password" if replies[0] != calcpass or replies[1] != data.name
				callback null, replies[1]

	hooks =
		grantClientToken: (clientId, clientSecret, cb) ->
			if env.data.redis.last_error
				return cb new env.utilities.check.Error env.data.redis.last_error
			next = ->
				token = env.data.generateUid()
				(env.data.redis.multi [
					['hmset', 'session:' + token, 'date', (new Date).getTime()]
					['expire', 'session:' + token, _config.expire]
				]).exec (err, r) ->
					return cb err if err
					return cb null, token
			db_login name:clientId, pass:clientSecret, (err, res) ->
				if err
					return cb null, false if err.message == "Invalid email or password"
					return cb err if err
				return next() if res
				db_register name:clientId, pass:clientSecret, (err, res) ->
					return cb err if err
					next()


		authenticateToken: (token, cb) ->
			return cb null, false if env.data.redis.last_error
			env.data.redis.hgetall 'session:' + token, (err, res) ->
				return cb err if err
				return cb null, false if not res
				return cb null, res

	auth.init = ->
		restifyOAuth2.cc env.server,
			hooks:hooks, tokenEndpoint: env.config.base + '/token',
			tokenExpirationTime: _config.expire


	# auth plugin specific
	auth.needed = (req, res, next) ->
		cb = ->
			req.user = req.clientId
			req.body ?= {}
			next()
		return cb() if env.data.redis.last_error
		return cb() if req.clientId
		# token = req.headers.cookie?.match /accessToken=%22(.*?)%22/
		token = req.headers.Authorization.replace /^Bearer /, ''
		console.log 'token', token
		return next new restify.ResourceNotFoundError req.url + ' does not exist' if not token
		env.data.redis.hget 'session:' + token, 'date', (err, res) ->
			return next new restify.ResourceNotFoundError req.url + ' does not exist' if not res
			req.clientId = 'admin'
			cb()

	auth.optional = (req, res, next) ->
		cb = ->
			req.user = req.clientId
			req.body ?= {}
			next()
		return cb() if env.data.redis.last_error
		return cb() if req.clientId
		token = req.headers.cookie?.match /accessToken=%22(.*?)%22/
		token = token?[1]
		return cb() if not token
		env.data.redis.hget 'session:' + token, 'date', (err, res) ->
			return cb() if not res
			req.clientId = 'admin'
			cb()

	auth.setup = (callback) ->
		env.server.post env.config.base + '/signin', (req, res, next) =>
			res.setHeader 'Content-Type', 'text/html'
			hooks.grantClientToken req.body.name, req.body.pass, (e, token) =>
				if not e and not token
					e = new env.utilities.check.Error 'Invalid email or password'
				if token
					expireDate = new Date((new Date - 0) + _config.expire * 1000)
					res.json {
						accessToken: token,
						expires: expireDate.getTime()
					}

				if e
					if e.status == "fail"
						if e.body.name
							e = new env.utilities.check.Error "Invalid email format"
						if e.body.pass
							e = new env.utilities.check.Error "Invalid password format (must be 6 characters min)"
					res.send 400, e.message
				next()
			
		env.server.get env.config.base + '/api/apps', auth.needed, (req, res, next) ->
			env.data.apps.getByOwner 'undefined', (err, apps) ->
				res.json apps

		callback()


	auth

