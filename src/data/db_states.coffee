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

async = require 'async'

module.exports = (env) ->
	config = env.config
	check = env.utilities.check

	exp = {}

	# add a new state
	exp.add = check key:check.format.key, provider:check.format.provider
		, token:['none','string'], expire:['none','number'], oauthv:'string'
		, origin:['none','string'], redirect_uri:['none','string'], redirect_type:['none','string']
		, options:['none','object'], (data, callback) ->

			id =env.data.generateUid()
			dbdata = key:data.key, provider:data.provider
			dbdata.token = data.token if data.token
			dbdata.expire = (new Date()).getTime() + data.expire if data.expire
			dbdata.redirect_uri = data.redirect_uri if data.redirect_uri
			dbdata.redirect_type = data.redirect_type if data.redirect_type
			dbdata.oauthv = data.oauthv if data.oauthv
			dbdata.origin = data.origin if data.origin
			dbdata.options = JSON.stringify(data.options) if data.options
			dbdata.step = 0
			env.data.redis.hmset 'st:' + id, dbdata, (err, res) ->
				return callback err if err
				if data.expire?
					env.data.redis.expire 'st:' + id, data.expire
				dbdata.id = id
				callback null, dbdata

	# get the state infos
	exp.get = check check.format.key, (id, callback) ->
		env.data.redis.hgetall 'st:' + id, (err, res) ->
			return callback err if err
			return callback() if not res
			res.expire = parseInt res.expire if res?.expire
			res.id = id
			res.options = JSON.parse(res.options) if res.options
			callback null, res

	# set the state infos
	exp.set = check check.format.key
		, token:['none','string'], expire:['none','number']
		, origin:['none','string'], redirect_uri:['none','string']
		, step:['none','number'], (id, data, callback) ->

			env.data.redis.hmset 'st:' + id, data, callback

	# delete a state
	exp.del = check check.format.key, (id, callback) ->
		env.data.redis.del 'st:' + id, callback

	# set the state's token
	exp.setToken = check check.format.key, 'string', (id, token, callback) ->
		env.data.redis.hset 'st:' + id, 'token', token, callback

	exp
