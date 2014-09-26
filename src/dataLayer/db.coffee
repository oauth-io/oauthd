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
redis = require 'redis'

module.exports = (env) ->
	exp = {}

	
	config = env.config
	exit = env.utilities.exit

	exp.redis = redis.createClient config.redis.port, config.redis.host, config.redis.options
	exp.redis.auth(config.redis.password) if config.redis.password
	exp.redis.select(config.redis.database) if config.redis.database

	exp.redis.on 'error', (err) ->
		exp.redis.last_error = 'Error while connecting to redis DB (' + err.message + ')'
		console.error exp.redis.last_error

	exit.push 'Redis db', (callback) ->
		try
			exp.redis.quit() if exp.redis
		catch e
			return callback e
		callback()

	exp.generateUid = (data) ->
		data ?= ''
		shasum = crypto.createHash 'sha1'
		shasum.update config.publicsalt
		shasum.update data + (new Date).getTime() + ':' + Math.floor(Math.random()*9999999)
		uid = shasum.digest 'base64'
		return uid.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '')

	exp.generateHash = (data) ->
		shasum = crypto.createHash 'sha1'
		shasum.update config.staticsalt + data
		return shasum.digest 'base64'

	exp.emptyStrIfNull = (val) ->
		return new String("") if not val? or val.length == 0
		return val

	#inits env.DAL.db
	env.DAL.db = exp
