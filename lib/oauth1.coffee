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

querystring = require 'querystring'
crypto = require 'crypto'

async = require 'async'
request = require 'request'

check = require './check'
db = require './db'
dbstates = require './db_states'
dbproviders = require './db_providers'
dbapps = require './db_apps'
config = require './config'

OAuth1ResponseParser = require './oauth1-response-parser'
OAuthBase = require './oauth-base'

class OAuth1 extends OAuthBase
	constructor: ->
		super 'oauth1'

	authorize: (provider, parameters, opts, callback) ->
		@_setParams provider.parameters
		@_setParams provider.oauth1.parameters
		@_createState provider, opts, (err, state) =>
			return callback err if err
			@_getRequestToken state, provider, parameters, opts, callback

	_getRequestToken: (state, provider, parameters, opts, callback) ->
		request_token = provider.oauth1.request_token
		query = {}
		if typeof opts.options?.request_token == 'object'
			query = opts.options.request_token
		for name, value of request_token.query
			param = @_replaceParam value, state:state.id, callback:config.host_url+config.relbase, parameters
			query[name] = param if param
		headers = {}
		headers["Accept"] = @_short_formats[request_token.format] || request_token.format if request_token.format
		for name, value of request_token.headers
			param = @_replaceParam value, {}, parameters
			headers[name] = param if param
		options =
			url: request_token.url
			method: request_token.method?.toUpperCase() || "POST"
			encoding: null
			oauth:
				callback: query.oauth_callback
				consumer_key: parameters.client_id
				consumer_secret: parameters.client_secret
		delete query.oauth_callback
		options.headers = headers if Object.keys(headers).length
		if options.method == 'POST'
			options.form = query
		else
			options.qs = query

		# do request to request_token
		request options, (err, response, body) =>
			return callback err if err
			@_parseGetRequestTokenResponse(response, body, provider, parameters, opts, headers, state, callback)

	_parseGetRequestTokenResponse: (response, body, provider, parameters, opts, headers, state, callback) ->
		responseParser = new OAuth1ResponseParser(response, body, headers["Accept"], 'request_token')
		responseParser.parse (err, response) =>
			return callback err if err
			dbstates.setToken state.id, response.oauth_token_secret, (err, returnCode) =>
				return callback err if err
				callback null, @_generateRequestTokenAuthorizeUrl(state, provider, parameters, opts, response)

	_generateRequestTokenAuthorizeUrl: (state, provider, parameters, opts, response) ->
		authorize = provider.oauth1.authorize
		query = {}
		if typeof opts.options?.authorize == 'object'
			query = opts.options.authorize
		for name, value of authorize.query
			param = @_replaceParam value, state:state.id, callback:config.host_url+config.relbase, parameters
			query[name] = param if param
		query.oauth_token = response.oauth_token
		url = @_replaceParam authorize.url, {}, parameters
		url += "?" + querystring.stringify query
		return url:url, state:state.id

	access_token: (state, req, callback) ->
		if not req.params.oauth_token && not req.params.error
			req.params.error_description ?= 'Authorization refused'

		# manage errors in callback
		if req.params.error || req.params.error_description
			err = new check.Error
			err.error req.params.error_description || 'Error while authorizing'
			err.body.error = req.params.error if req.params.error
			err.body.error_uri = req.params.error_uri if req.params.error_uri
			return callback err

		# get infos from state
		async.parallel [
			(callback) -> dbproviders.getExtended state.provider, callback
			(callback) -> dbapps.getKeyset state.key, state.provider, callback
		], (err, res) =>
			return callback err if err
			[provider, {parameters,response_type}] = res
			err = new check.Error
			if provider.oauth1.authorize.ignore_verifier == true
				err.check req.params, oauth_token:'string'
			else
				err.check req.params, oauth_token:'string', oauth_verifier:'string'
			return callback err if err.failed()
			@_setParams provider.parameters
			@_setParams provider.oauth1.parameters

			access_token = provider.oauth1.access_token
			query = {}
			hard_params = state:state.id, callback:config.host_url+config.relbase
			for extra in (provider.oauth1.authorize.extra||[])
				hard_params[extra] = req.params[extra] if req.params[extra]
			for name, value of access_token.query
				param = @_replaceParam value, hard_params, parameters
				query[name] = param if param
			headers = {}
			headers["Accept"] = @_short_formats[access_token.format] || access_token.format if access_token.format
			for name, value of access_token.headers
				param = @_replaceParam value, {}, parameters
				headers[name] = param if param
			options =
				url: @_replaceParam access_token.url, hard_params, parameters
				method: access_token.method?.toUpperCase() || "POST"
				encoding: null
				oauth:
					callback: query.oauth_callback
					consumer_key: parameters.client_id
					consumer_secret: parameters.client_secret
					token: req.params.oauth_token
					token_secret: state.token
			if provider.oauth1.authorize.ignore_verifier != true
				options.oauth.verifier = req.params.oauth_verifier
			else
				options.oauth.verifier = ""
			delete query.oauth_callback

			options.headers = headers if Object.keys(headers).length
			if options.method == 'POST'
				options.form = query
			else
				options.qs = query

			# do request to access_token
			request options, (e, r, body) =>
				return callback(e) if e
				responseParser = new OAuth1ResponseParser(r, body, headers["Accept"], 'access_token')
				responseParser.parse (err, response) =>
					return callback err if err

					expire = response.body.expire
					expire ?= response.body.expires
					expire ?= response.body.expires_in
					expire ?= response.body.expires_at
					if expire
						expire = parseInt expire
						now = (new Date).getTime()
						expire -= now if expire > now
					requestclone = {}
					requestclone[k] = v for k, v of provider.oauth1.request
					for k, v of @_params
						if v.scope == 'public'
							requestclone.parameters ?= {}
							requestclone.parameters[k] = parameters[k]
					result =
						oauth_token: response.oauth_token
						oauth_token_secret: response.oauth_token_secret
						expires_in: expire
						request: requestclone
					for extra in (access_token.extra||[])
						result[extra] = response.body[extra] if response.body[extra]
					for extra in (provider.oauth1.authorize.extra||[])
						result[extra] = req.params[extra] if req.params[extra]
					callback null, result

	request: (provider, parameters, req, callback) ->
		@_setParams provider.parameters
		@_setParams provider.oauth1.parameters

		if ! parameters.oauthio.oauth_token || ! parameters.oauthio.oauth_token_secret
			return callback new check.Error "You must provide 'oauth_token' and 'oauth_token_secret' in 'oauthio' http header"

		oauthrequest = provider.oauth1.request

		options =
			method: req.method
			followAllRedirects: true

		# build url
		options.url = decodeURIComponent(req.params[1])
		if ! options.url.match(/^[a-z]{2,16}:\/\//)
			if options.url[0] != '/'
				options.url = '/' + options.url
			options.url = oauthrequest.url + options.url
		options.url = @_replaceParam options.url, parameters.oauthio, parameters

		# build query
		options.qs = {}
		options.qs[name] = value for name, value of req.query
		for name, value of oauthrequest.query
			param = @_replaceParam value, parameters.oauthio, parameters
			options.qs[name] = param if param

		options.oauth =
			consumer_key: parameters.client_id
			consumer_secret: parameters.client_secret
			token: parameters.oauthio.oauth_token
			token_secret: parameters.oauthio.oauth_token_secret

		# build headers
		options.headers =
			accept:req.headers.accept
			'accept-encoding':req.headers['accept-encoding']
			'accept-language':req.headers['accept-language']
			'content-type':req.headers['content-type']
			'User-Agent': 'OAuth.io'
		for name, value of oauthrequest.headers
			param = @_replaceParam value, parameters.oauthio, parameters
			options.headers[name] = param if param

		# build body
		if req.method == "PATCH" || req.method == "POST" || req.method == "PUT"
			options.body = req._body || req.body
			delete options.body if typeof options.body == 'object'

		# do request
		callback null, request(options)

module.exports = OAuth1
