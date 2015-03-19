# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

crypto = require 'crypto'
async = require 'async'

module.exports = (env) ->
	data = {}

	if env.mode != 'test'
		redis = require 'redis'
	else
		redis = require 'fakeredis'

	config = env.config
	exit = env.utilities.exit
	data.redis = redis.createClient config.redis.port || 6379, config.redis.host || '127.0.0.1', config.redis.options || {}
	data.redis.auth(config.redis.password) if config.redis.password
	data.redis.select(config.redis.database) if config.redis.database

	oldkeys = data.redis.keys
	data.redis.keys = (pattern, cb) ->
		keys_response = []
		cursor = -1
		async.whilst () ->
			return cursor != '0'
		, (next) ->
			if cursor == -1
				cursor = 0
			data.redis.send_command 'SCAN', [cursor, 'MATCH', pattern, 'COUNT', 100000], (err, response) ->
				if err
					return next(err)
				cursor = response[0]
				keys_array = response[1]
				keys_response = keys_response.concat keys_array
				next()
		, (err) ->
			return cb err if err
			cb null, keys_response




	oldhgetall = data.redis.hgetall
	data.redis.hgetall = (key, pattern, cb) ->
		if not cb?
			cb  = pattern
			pattern = '*'
		final_response = {}
		cursor = undefined
		async.whilst () ->
			return cursor != '0'
		, (next) ->
			if cursor == undefined
				cursor = 0
			data.redis.send_command 'HSCAN', [key, cursor, 'MATCH', pattern, 'COUNT', 100], (err, response) ->
				if err
					return next(err)
				cursor = response[0]
				array = response[1]
				for i in [0..array.length] by 2
					if array[i] and array[i+1]
						final_response[array[i]] = array[i+1]
				next()
		, (err) ->
			return cb err if err
			cb null, final_response



	data.redis.on 'error', (err) ->
		data.redis.last_error = 'Error while connecting to redis DB (' + err.message + ')'
		console.error data.redis.last_error

	exit.push 'Redis db', (callback) ->
		try
			data.redis.quit() if data.redis
		catch e
			return callback e
		callback()

	data.generateUid = (data) ->
		data ?= ''
		shasum = crypto.createHash 'sha1'
		shasum.update config.publicsalt
		shasum.update data + (new Date).getTime() + ':' + Math.floor(Math.random()*9999999)
		uid = shasum.digest 'base64'
		return uid.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '')

	data.generateHash = (data) ->
		shasum = crypto.createHash 'sha1'
		shasum.update config.staticsalt + data
		return shasum.digest 'base64'

	data.emptyStrIfNull = (val) ->
		return new String("") if not val? or val.length == 0
		return val

	data
