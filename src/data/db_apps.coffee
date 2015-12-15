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

restify = require 'restify'
Url = require 'url'
async = require 'async'

module.exports = (env) ->

	config = env.config
	check = env.utilities.check
	plugins = env.plugins


	App = {}

	# create a new app
	App.create = (data, user, callback) ->
		err = new check.Error
		err.check data, name:/^.{3,50}$/,domains:['none','array']
		if err.failed()
			return callback new check.Error "You must specify a name and at least one domain for your application."

		key = env.data.generateUid()
		secret = env.data.generateUid()
		err = new check.Error
		if data.domains
			for domain in data.domains
				err.check 'domains', domain, 'string'
		if err.failed()
			return callback new check.Error "You must specify a name and at least one domain for your application."
		if not user?.id?
			return callback new check.Error "The user must be defined and contain the field 'id'"
		env.data.redis.incr 'a:i', (err, idapp) ->
			return callback err if err
			prefix = 'a:' + idapp + ':'
			cmds = [
				[ 'mset',
					prefix+'name', data.name,
					prefix+'key', key,
					prefix+'secret', secret,
					prefix+'owner', user.id,
					prefix+'date', (new Date).getTime() ],
				[ 'hset', 'a:keys', key, idapp ]
			]
			if data.domains
				# todo: in redis >= 2.4, sadd accepts multiple members
				for domain in data.domains
					cmds.push [ 'sadd', prefix + 'domains', domain ]
			env.data.redis.multi(cmds).exec (err, res) ->
				return callback err if err
				return callback null, id:idapp, name:data.name, key:key

	# get the app infos by its id
	App.getByOwner = (owner_id, callback) ->
		env.data.redis.smembers 'u:' + owner_id + ':apps', (err, app_ids) ->
			return callback err if err
			apps = []
			async.eachSeries app_ids, (id, cb) ->
				env.data.App.findById id
					.then (app) ->
						apps.push app.props
						cb()
					.fail (e) ->
						cb e
			, (err) ->
				return callback err if err
				callback null, apps



	# get the app infos by its id
	App.getById = check 'int', (idapp, callback) ->
		prefix = 'a:' + idapp + ':'
		env.data.redis.mget [prefix+'name', prefix+'key', prefix+'secret', prefix + 'date', prefix + 'owner'], (err, replies) ->
			return callback err if err
			callback null, id:idapp, name:replies[0], key:replies[1], secret:replies[2], date: replies[3], owner: replies[4]

	# get the app infos
	App.get = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			prefix = 'a:' + idapp + ':'
			env.data.redis.mget [prefix+'name', prefix+'key', prefix+'secret', prefix + 'date', prefix + 'owner', prefix+'backend:name', prefix+'backend:value'], (err, replies) ->
				return callback err if err
				if replies[5]
					backend = {
						name: replies[5],
					}
					try
						backend.value = JSON.parse(replies[6])
					catch e
						backend.value = {}
				server_side_only = backend?.name? and not backend.value?.client_side
				callback null, id:idapp, name:replies[0], key:replies[1], secret:replies[2], date:replies[3], owner: replies[4], server_side_only: server_side_only, backend: backend

	# update app infos
	App.update = check check.format.key, name:['none',/^.{3,50}$/], domains:['none','array'], (key, data, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			async.parallel [
				(callback) ->
					upinfos = []
					if data.name
						upinfos.push 'a:' + idapp + ':name'
						upinfos.push data.name
					return callback() if not upinfos.length
					env.data.redis.mset upinfos, ->
						return callback err if err
						return callback()
				(callback) ->
					return callback() if not data.domains
					App.updateDomains key, data.domains, (err, res) ->
						return callback err if err
						return callback()
			], (err, res) ->
				return callback err if err
				return callback()

	# reset app key
	App.resetKey = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			newkey = env.data.generateUid()
			newsecret = env.data.generateUid()
			env.data.redis.multi([
				['mset', 'a:' + idapp + ':key', newkey, 'a:' + idapp + ':secret', newsecret]
				['hdel', 'a:keys', key]
				['hset', 'a:keys', newkey, idapp]
			]).exec (err, r) ->
				return callback err if err
				env.events.emit 'app.resetkey', newkey
				callback null, key:newkey, secret:newsecret

	# remove an app
	App.remove = check check.format.key, (key, callback) ->
		App.getKeysets key, (err, providers) ->
			return callback err if err
			for provider in providers
				env.events.emit 'app.remkeyset', provider:provider, app:key
			env.data.redis.hget 'a:keys', key, (err, idapp) ->
				return callback err if err
				return callback new check.Error 'Unknown key' unless idapp
				env.data.redis.multi([
					['hdel', 'a:keys', key],
					['keys', 'a:' + idapp + ':*']
				]).exec (err, replies) ->
					return callback err if err
					env.data.redis.del replies[1], (err, removed) ->
						return callback err if err
						return callback()

	# get authorized domains of the app
	App.getDomains = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.smembers 'a:' + idapp + ':domains', callback

	# update all authorized domains of the app
	App.updateDomains = check check.format.key, 'array', (key, domains, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp

			cmds = [['del', 'a:' + idapp + ':domains']]
			# todo: in redis >= 2.4, sadd accepts multiple members
			for domain in domains
				cmds.push [ 'sadd', 'a:' + idapp + ':domains', domain ]

			env.data.redis.multi(cmds).exec (err, res) ->
				return callback err if err
				return callback()

	# add an authorized domain to an app
	App.addDomain = check check.format.key, 'string', (key, domain, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.sadd 'a:' + idapp + ':domains', domain, (err, res) ->
				return callback err if err
				return callback new check.Error 'domain', domain + ' is already valid' if not res
				callback()

	# remove an authorized domain from an app
	App.remDomain = check check.format.key, 'string', (key, domain, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.srem 'a:' + idapp + ':domains', domain, (err, res) ->
				return callback err if err
				return callback new check.Error 'domain', domain + ' is already non-valid' if not res
				callback()

	# get the backend of an app
	App.getBackend = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			App.getBackendById idapp, callback

	App.getBackendById = (idapp, callback) ->
		env.data.redis.mget 'a:' + idapp + ':backend:name', 'a:' + idapp + ':backend:value', (err, res) ->
			return callback err if err
			return callback null, null if not res[0] or not res[1]
			res[1] = JSON.parse(res[1]) if typeof res[1] == 'string'
			return callback null, name:res[0], value:res[1]

	# set (or update) the backend of an app
	App.setBackend = check check.format.key, 'string', 'object', (key, name, backend, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.mset 'a:' + idapp + ':backend:name', name, 'a:' + idapp + ':backend:value', JSON.stringify(backend), (err, res) ->
				return callback err if err
				callback()

	# remove the backend from an app
	App.remBackend = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.del 'a:' + idapp + ':backend:name', 'a:' + idapp + ':backend:value', (err, res) ->
				return callback err if err
				callback()

	# get keys infos of an app for a provider
	App.getKeyset = check check.format.key, 'string', (key, provider, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			App.getOptionsById idapp, (err, options) ->
				return callback err if err
				App.getBackendById idapp, (err, backend) ->
					env.data.redis.mget 'a:' + idapp + ':k:' + provider, (err, res) ->
						return callback err if err
						if res[0]
							try
								res[0] = JSON.parse(res[0])
							catch e
								return callback err if err
						if not backend?.value? || backend?.value?.client_side
							response_type = 'both'
						else
							response_type = 'code'
						callback null, parameters:(res[0] || {}), response_type:response_type, options:options

	App.setOptions = check check.format.key, 'object', (key, options, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.hmset 'a:' + idapp + ':opts', options, (err, res) ->
				return callback err if err
				callback null, 'options updated'

	App.getOptions = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			App.getOptionsById idapp, callback

	App.getOptionsById = (idapp, callback) ->
		env.data.redis.hgetall 'a:' + idapp + ':opts', (err, options) ->
			return callback err if err
			if options
				for k, v of options
					options[k] = true if v == "true"
					options[k] = false if v == "false"
			callback null, options || {}

	App.getKeysetWithResponseType = check check.format.key, 'string', (key, provider, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.mget 'a:' + idapp + ':k:' + provider
				, 'a:' + idapp + ':ktype:' + provider, (err, res) ->
					return callback err if err
					if res[0]
						try
							res[0] = JSON.parse(res[0])
						catch e
							return callback err if err
					callback null, parameters:(res[0] || {}), response_type:(res[1] || 'token')

	# get keys infos of an app for a provider
	App.addKeyset = check check.format.key, 'string', parameters:'object', (key, provider, data, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.exists 'a:' + idapp + ':k:' + provider, (err, isUpdate) ->
				return callback err if err
				env.data.redis.mset 'a:' + idapp + ':k:' + provider, JSON.stringify(data.parameters)
					#, 'a:' + idapp + ':ktype:' + provider, data.response_type
					, 'a:' + idapp + ':kdate:' + provider, (new Date).getTime(), (err, res) ->
						return callback err if err
						eventName = if isUpdate then 'app.updatekeyset' else 'app.addkeyset'
						env.events.emit eventName, provider:provider, app:key, id:idapp
						env.data.redis.sadd 'a:' + idapp + ':providers', provider, (err) ->
							return callback err if err
							callback()

	# get keys infos of an app for a provider
	App.remKeyset = check check.format.key, 'string', (key, provider, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.get 'a:' + idapp + ':k:' + provider, (err, raw_keyset) ->
				try
					keyset = JSON.parse raw_keyset
				catch e
					keyset = {}
				finally
					env.data.redis.del 'a:' + idapp + ':k:' + provider, 'a:' + idapp + ':ktype:' + provider, 'a:' + idapp + ':kdate:' + provider, (err, res) ->
						return callback err if err
						return callback new check.Error 'provider', 'You have no keyset for ' + provider if not res
						env.events.emit 'app.remkeyset', provider:provider, app:key, id:idapp, keyset: keyset
						env.data.redis.srem 'a:' + idapp + ':providers', provider, (err) ->
							return callback err if err
							callback()
	
	App.getAccess = check check.format.key, 'string', (key, id, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.hget 'a:' + idapp + ':access', id, (err, access) ->
				return callback err if err
				return callback null, [] if ! access
				return callback null, JSON.parse(access)
	
	App.setAccess = check check.format.key, 'string', ['array', 'null'], (key, id, access, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			if not access or not access.length
				env.data.redis.hdel 'a:' + idapp + ':access', id, (err) ->
					env.events.emit 'app.delAccess', key, id
					return callback err if err
					return callback()
			else
				env.data.redis.hset 'a:' + idapp + ':access', id, JSON.stringify(access), (err) ->
					env.events.emit 'app.setAccess', key, id, access
					return callback err if err
					return callback()
	
	App.getAccessList = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.hgetall 'a:' + idapp + ':access', (err, _access_list) ->
				return callback err if err
				access_list = {}
				for k,v of _access_list
					access_list[k] = JSON.parse(v)
				return callback null, access_list

	# get keys infos of an app for all providers
	App.getKeysets = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			prefix = 'a:' + idapp
			providers_key = prefix + ':providers'
			env.data.redis.smembers providers_key, (err, providers) ->
				return callback err if err
				if providers?.length > 0
					callback null, providers
				else
					env.data.redis.get prefix + ':stored_keysets', (err, v) ->
						if v != '1'
							env.data.redis.set prefix + ':stored_keysets', '1', (err) ->
								env.data.redis.keys prefix + ':k:*', (err, provider_keys) ->
									return callback err if err
									commands = []
									providers = []
									for key in provider_keys
										p = key.replace(prefix + ':k:', '')
										providers.push p
										commands.push ['sadd', providers_key, p]
									env.data.redis.multi(commands).exec (err) ->
										return callback err if err
										callback null, providers
						else
							callback null, providers

	# check a domain
	App.checkDomain = check check.format.key, 'string', (key, domain_str, callback) ->
		App.getDomains key, (err, domains) ->
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

	# get owner user
	App.getOwner = check check.format.key, (key, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.get 'a:' + idapp + ':owner', (err, iduser) ->
				return callback err if err
				if not iduser
					return callback new check.Error 'Could not find app owner'
				return callback null, id:iduser

	# check the secret
	App.checkSecret = check check.format.key, check.format.key, (key, secret, callback) ->
		env.data.redis.hget 'a:keys', key, (err, idapp) ->
			return callback err if err
			return callback new check.Error 'Unknown key' unless idapp
			env.data.redis.get 'a:' + idapp + ':secret', (err, sec) ->
				return callback err if err
				return callback null, sec == secret


	App
