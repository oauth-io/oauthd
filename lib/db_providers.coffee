# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

fs = require "fs"
Path = require "path"

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


providers = _list:{}, _expire:0

providers.list = ->
		now = (new Date).getTime()
		if now > providers._expire
			fs.readdir config.rootdir + '/providers', (err, files) ->
				return if err
				for file in files
					if file.match /\.json$/
						providers._list[file.substr(0, file.length - 5)] ?= expire:0
			providers._expire = now + 30000
		return providers._list
providers.list()

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
	provider = providers._list[name] ?= expire:0
	now = (new Date).getTime()
	if now > provider.expire
		exports.get name, (err, res) ->
			return callback err if err
			for oauthv in ['oauth1','oauth2']
				if res[oauthv]?
					found_state = false
					for endpoint_name in ['request_token', 'authorize', 'access_token']
						continue if oauthv == 'oauth2' && endpoint_name == 'request_token'
						endpoint = res[oauthv][endpoint_name]
						if typeof endpoint == 'string'
							endpoint = res[oauthv][endpoint_name] = url:endpoint
						endpoint.url = res.url + endpoint.url if res.url
						if not endpoint.query
							endpoint.query = {}
							endpoint.query[k] = v for k,v of def[oauthv][endpoint_name].query
						for k,v of endpoint.query
							if v.indexOf('{{state}}') != -1
								found_state = true
								break
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
			provider.expire = now + 30000
			callback null, res
	else
		callback null, provider.data

# get providers list
exports.getList = (callback) ->
	callback null, Object.keys(providers.list())