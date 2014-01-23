# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

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
		request:
			headers:
				"Authorization": "Bearer {{token}}"
		refresh:
			query:
				client_id: "{client_id}"
				client_secret: "{client_secret}"
				grant_type: "refresh_token"
				refresh_token: "{{refresh_token}}"
		revoke: {}
	oauth1:
		request_token:
			query:
				oauth_callback: "{{callback}}"
		authorize: {}
		access_token:
			query: {}
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
	provider = providers._list[name]
	if provider?.cache
		return callback null, provider.data

	exports.get name, (err, res) ->
		return callback err if err
		provider = providers._list[name] ?= cache:false
		base_url = ""
		if res.url
			base_url = res.url.match(/^.{2,5}:\/\/[^/]+/)[0] || "";
		for oauthv in ['oauth1','oauth2']
			if res[oauthv]?
				found_state = false
				for endpoint_name in ['request_token', 'authorize', 'access_token', 'request', 'refresh', 'revoke']
					continue if oauthv == 'oauth2' && endpoint_name == 'request_token'
					endpoint = res[oauthv][endpoint_name]
					if endpoint_name == 'request' && not endpoint
						endpoint = res[oauthv][endpoint_name] = {}
					if not endpoint
						res[oauthv][endpoint_name] = {}
						continue
					if typeof endpoint == 'string'
						endpoint = res[oauthv][endpoint_name] = url:endpoint
					endpoint.url = res.url + endpoint.url if res.url && endpoint.url?[0] == '/'
					if endpoint_name == 'request'
						endpoint.url = base_url if not endpoint.url
						fillRequired = (str) ->
							hardparamRegexp = /\{\{(.+?)\}\}/g
							while matches = hardparamRegexp.exec str
								if matches[1] != 'token'
									endpoint.required ?= []
									endpoint.required.push matches[1]
						fillRequired endpoint.url
						if endpoint.query
							fillRequired v for k, v of endpoint.query
						if endpoint.headers
							fillRequired v for k, v of endpoint.headers
					if not endpoint.query && endpoint_name == 'authorize' && endpoint.ignore_verifier
						endpoint.query = oauth_callback:'{{callback}}'
					if not endpoint.query && def[oauthv][endpoint_name].query
						endpoint.query = {}
						endpoint.query[k] = v for k,v of def[oauthv][endpoint_name].query
					if not endpoint.headers && not endpoint.query && def[oauthv][endpoint_name].headers
						endpoint.headers = {}
						endpoint.headers[k] = v for k,v of def[oauthv][endpoint_name].headers
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
						params[k].type = 'string' if not params[k].type
						params[k].cardinality = '*' if params[k].values && not params[k].cardinality
						params[k].separator = ' ' if params[k].values && not params[k].separator
		if not res.oauth1?.parameters && not res.oauth2?.parameters && not res.parameters
			res.parameters = client_id:'string', client_secret:'string'
		params = res.parameters
		if params
			for k,v of params
				params[k] = type:v if typeof v == 'string'
				params[k].type = 'string' if not params[k].type
				params[k].cardinality = '*' if params[k].values && not params[k].cardinality
				params[k].separator = ' ' if params[k].values && not params[k].separator
		provider.data = res
		provider.cache = true
		callback null, res
