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

fs = require "fs"
Path = require "path"

async = require "async"

config = require "./config"
check = require "./check"

def =
	oauth2:
		authorize:
			query:
				client_id: "{client_id}"
				response_type: "code"
				redirect_uri: "{{callback}}"
				scope: "{scope}"
				state: "{{state}}"
		access_token:
			query:
				client_id: "{client_id}"
				client_secret: "{client_secret}"
				redirect_uri: "{{callback}}"
				grant_type: "authorization_code"
				code: "{{code}}"
		request: {}
		refresh: {}
		revoke: {}
	oauth1:
		request_token:
			query:
				oauth_consumer_key: "{client_id}"
				oauth_callback: "{{callback}}"
		authorize: {}
		access_token:
			query:
				oauth_consumer_key: "{client_id}"
		request: {}


providers = _list:{}, _cached:false

# get providers list
exports.getList = (callback) ->
	if not providers._cached
		fs.readdir config.rootdir + '/providers', (err, files) ->
			return callback err if err
			cmds = []
			for file in files
				do (file) ->
					if file.match /\.json$/
						cmds.push (callback) ->
							provider = file.substr(0, file.length - 5)
							exports.get provider, (err, data) ->
								if err
									console.error "Error in " + provider + ".json:", err, "skipping this provider"
									return callback null
								providers._list[provider] ?= cached:false, name:(data.name || provider)
								callback null
			async.parallel cmds, (err, res) ->
				return callback err if err
				providers._cached = true
				return callback null, ({provider:k, name:v.name} for k,v of providers._list)
	else
		return callback null, ({provider:k, name:v.name} for k,v of providers._list)

# get a provider's description
exports.get = (provider, callback) ->
	provider_name = provider
	providers_dir = config.rootdir + '/providers'
	provider = Path.resolve providers_dir, provider + '.json'
	if Path.relative(providers_dir, provider).substr(0,2) == ".."
		return callback new check.Error 'Not authorized'

	fs.readFile provider, (err, data) ->
		if err?.code == 'ENOENT'
			return callback new check.Error 'No such provider: ' + provider_name
		return callback err if err
		content = null
		try
			content = JSON.parse data
		catch err
			return callback err
		content.provider = provider_name
		callback null, content

# get a provider's description extended with default params
exports.getExtended = (name, callback) ->
	provider = providers._list[name] ?= cache:false
	if not provider.cache
		exports.get name, (err, res) ->
			return callback err if err
			for oauthv in ['oauth1','oauth2']
				if res[oauthv]?
					found_state = false
					for endpoint_name in ['request_token', 'authorize', 'access_token', 'request', 'refresh', 'revoke']
						continue if oauthv == 'oauth2' && endpoint_name == 'request_token'
						endpoint = res[oauthv][endpoint_name]
						if not endpoint
							res[oauthv][endpoint_name] = {}
							continue
						if typeof endpoint == 'string'
							endpoint = res[oauthv][endpoint_name] = url:endpoint
						endpoint.url = res.url + endpoint.url if res.url && endpoint.url?[0] == '/'
						if not endpoint.query && def[oauthv][endpoint_name].query
							endpoint.query = {}
							endpoint.query[k] = v for k,v of def[oauthv][endpoint_name].query
						for k,v of endpoint.query
							if v.indexOf('{{state}}') != -1
								found_state = true
							if v.indexOf('{scope}') != -1 && ! res[oauthv].parameters?.scope && ! res.parameters?.scope
								delete endpoint.query[k]
						if not found_state
							for k,v of endpoint.query
								endpoint.query[k] = v.replace /\{\{callback\}\}/g, '{{callback}}?state={{state}}'
					params = res[oauthv].parameters
					if params
						for k,v of params
							params[k] = type:v if typeof v == 'string'
			params = res.parameters
			if params
				for k,v of params
					params[k] = type:v if typeof v == 'string'
			provider.data = res
			provider.cache = true
			callback null, res
	else
		callback null, provider.data
