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

Url = require 'url'

async = require 'async'

db = require './db'
config = require './config'
check = require './check'
plugins = require './plugins'

# create a new app
exports.create = check name:/^.{3,50}$/,domains:['none','array'], (data, callback) ->
	key = db.generateUid()
	secret = db.generateUid()
	err = new check.Error
	if data.domains
		for domain in data.domains
			err.check 'domains', domain, 'string'
	return callback err if err.failed()
	db.redis.incr 'a:i', (err, idapp) ->
		return callback err if err
		prefix = 'a:' + idapp + ':'
		cmds = [
			[ 'mset', prefix+'name', data.name,
				prefix+'key', key, prefix+'secret', secret ],
			[ 'hset', 'a:keys', key, idapp ]
		]
		if data.domains
			# todo: in redis >= 2.4, sadd accepts multiple members
			for domain in data.domains
				cmds.push [ 'sadd', prefix + 'domains', domain ]
		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err
			callback null, id:idapp, name:data.name, key:key

# get the app infos by its id
exports.getById = check 'int', (idapp, callback) ->
	prefix = 'a:' + idapp + ':'
	db.redis.mget [prefix+'name', prefix+'key', prefix+'secret'], (err, replies) ->
		return callback err if err
		callback null, id:idapp, name:replies[0], key:replies[1], secret:replies[2]

# get the app infos
exports.get = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		prefix = 'a:' + idapp + ':'
		db.redis.mget [prefix+'name', prefix+'key', prefix+'secret'], (err, replies) ->
			return callback err if err
			callback null, id:idapp, name:replies[0], key:replies[1], secret:replies[2]

# update app infos
exports.update = check check.format.key, name:['none',/^.{3,15}$/], domains:['none','array'], (key, data, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		async.parallel [
			(callback) ->
				upinfos = []
				if data.name
					upinfos.push 'a:' + idapp + ':name'
					upinfos.push data.name
				return callback() if not upinfos.length
				db.redis.mset upinfos, ->
					return callback err if err
					return callback()
			(callback) ->
				return callback() if not data.domains
				exports.updateDomains key, data.domains, (err, res) ->
					return callback err if err
					return callback()
		], (err, res) ->
			return callback err if err
			return callback()

# reset app key
exports.resetKey = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		newkey = db.generateUid()
		newsecret = db.generateUid()
		db.redis.multi([
			['mset', 'a:' + idapp + ':key', newkey, 'a:' + idapp + ':secret', newsecret]
			['hdel', 'a:keys', key]
			['hset', 'a:keys', newkey, idapp]
		]).exec (err, r) ->
			return callback err if err
			callback null, key:newkey, secret:newsecret

# remove an app
exports.remove = check check.format.key, (key, callback) ->
	exports.getKeysets key, (err, providers) ->
		return callback err if err
		for provider in providers
			plugins.data.emit 'app.remkeyset', provider:provider, app:key
		db.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			db.redis.multi([
				['hdel', 'a:keys', key],
				['keys', 'a:' + idapp + ':*']
			]).exec (err, replies) ->
				return callback err if err
				db.redis.del replies[1], (err, removed) ->
					return callback err if err
					return callback()

# get authorized domains of the app
exports.getDomains = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.smembers 'a:' + idapp + ':domains', callback

# update all authorized domains of the app
exports.updateDomains = check check.format.key, 'array', (key, domains, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp

		cmds = [['del', 'a:' + idapp + ':domains']]
		# todo: in redis >= 2.4, sadd accepts multiple members
		for domain in domains
			cmds.push [ 'sadd', 'a:' + idapp + ':domains', domain ]

		db.redis.multi(cmds).exec (err, res) ->
			return callback err if err
			return callback()

# add an authorized domain to an app
exports.addDomain = check check.format.key, 'string', (key, domain, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.sadd 'a:' + idapp + ':domains', domain, (err, res) ->
			return callback err if err
			return callback new check.Error 'domain', domain + ' is already valid' if not res
			callback()

# remove an authorized domain from an app
exports.remDomain = check check.format.key, 'string', (key, domain, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.srem 'a:' + idapp + ':domains', domain, (err, res) ->
			return callback err if err
			return callback new check.Error 'domain', domain + ' is already non-valid' if not res
			callback()

# get keys infos of an app for a provider
exports.getKeyset = check check.format.key, 'string', (key, provider, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.mget 'a:' + idapp + ':k:' + provider
			, 'a:' + idapp + ':ktype:' + provider, (err, res) ->
				return callback err if err
				return callback() if not res[0]
				try
					res[0] = JSON.parse(res[0])
				catch e
					return callback e
				callback null, parameters:res[0], response_type:(res[1] || 'token')


# get keys infos of an app for a provider
exports.addKeyset = check check.format.key, 'string', parameters:'object', response_type:'string', (key, provider, data, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.mset 'a:' + idapp + ':k:' + provider, JSON.stringify(data.parameters)
			, 'a:' + idapp + ':ktype:' + provider, data.response_type, (err, res) ->
				return callback err if err
				plugins.data.emit 'app.addkeyset', provider:provider, app:key, id:idapp
				callback()

# get keys infos of an app for a provider
exports.remKeyset = check check.format.key, 'string', (key, provider, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		db.redis.del 'a:' + idapp + ':k:' + provider, 'a:' + idapp + ':ktype:' + provider, (err, res) ->
			return callback err if err
			return callback new check.Error 'provider', 'You have no keyset for ' + provider if not res
			plugins.data.emit 'app.remkeyset', provider:provider, app:key
			callback()

# get keys infos of an app for all providers
exports.getKeysets = check check.format.key, (key, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		return callback new check.Error 'Unknown key' unless idapp
		prefix = 'a:' + idapp + ':k:'
		db.redis.keys prefix + '*', (err, replies) ->
			return callback err if err
			callback null, (reply.substr(prefix.length) for reply in replies)

# check a domain
exports.checkDomain = check check.format.key, 'string', (key, domain_str, callback) ->
	exports.getDomains key, (err, domains) ->
		return callback err if err
		domain = Url.parse domain_str
		if not domain.protocol
			domain_str = 'http://' + domain_str
			domain = Url.parse domain_str
		return callback null, true if domain.host == config.url.host
		for vdomain_str in domains
			vdomain_str = vdomain_str.replace '*', '.'
			if not vdomain_str.match /^.{1,}:\/\//
				vdomain_str = '.://' + vdomain_str
			vdomain = Url.parse vdomain_str
			continue if vdomain.protocol != '.:' && vdomain.protocol != domain.protocol
			continue if vdomain.port && vdomain.port != domain.port
			continue if vdomain.pathname && vdomain.pathname != '/' && vdomain.pathname != domain.pathname
			if vdomain.hostname == domain.hostname ||
				vdomain.hostname.substr(0,2) == '..' &&
				domain.hostname.substr(domain.hostname.length-vdomain.hostname.length+1) == vdomain.hostname.substr(1)
					return callback null, true
		return callback null, false

# check the secret
exports.checkSecret = check check.format.key, check.format.key, (key, secret, callback) ->
	db.redis.hget 'a:keys', key, (err, idapp) ->
		return callback err if err
		db.redis.get 'a:' + idapp + ':secret', (err, sec) ->
			return callback err if err
			return callback null, sec == secret