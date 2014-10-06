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


module.exports = (env) ->
	data = {}

	if env.mode is not 'test'
		redis = require 'redis'	
	else
		redis = require 'fakeredis'	

	config = env.config
	exit = env.utilities.exit

	data.redis = redis.createClient config.redis.port, config.redis.host, config.redis.options
	data.redis.auth(config.redis.password) if config.redis.password
	data.redis.select(config.redis.database) if config.redis.database

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
