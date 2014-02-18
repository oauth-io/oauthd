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
request = require 'request'

check = require './check'
dbstates = require './db_states'
config = require './config'

OAuth1ResponseParser = require './oauth1-response-parser'
OAuthBase = require './oauth-base'

class OAuth1 extends OAuthBase
	constructor: (provider, parameters) ->
		super 'oauth1', provider, parameters

	authorize: (opts, callback) ->
		@_createState @_provider, opts, (err, state) =>
			return callback err if err
			@_getRequestToken state, opts, callback

	_getRequestToken: (state, opts, callback) ->
		configuration = @_provider.oauth1.request_token
		placeholderValues = { state: state.id, callback: config.host_url + config.relbase }
		query = @_buildQuery(configuration.query, placeholderValues, opts.options?.request_token)
		headers = {}
		headers["Accept"] = @_short_formats[configuration.format] || configuration.format if configuration.format
		for name, value of configuration.headers
			param = @_replaceParam(value, {})
			headers[name] = param if param
		options =
			url: configuration.url
			method: configuration.method?.toUpperCase() || "POST"
			encoding: null
			oauth:
				callback: query.oauth_callback
				consumer_key: @_parameters.client_id
				consumer_secret: @_parameters.client_secret
		delete query.oauth_callback
		options.headers = headers if Object.keys(headers).length
		if options.method == 'POST'
			options.form = query
		else
			options.qs = query

		# do request to request_token
		request options, (err, response, body) =>
			return callback err if err
			@_parseGetRequestTokenResponse(response, body, opts, headers, state, callback)

	_parseGetRequestTokenResponse: (response, body, opts, headers, state, callback) ->
		responseParser = new OAuth1ResponseParser(response, body, headers["Accept"], 'request_token')
		responseParser.parse (err, response) =>
			return callback err if err
			dbstates.setToken state.id, response.oauth_token_secret, (err, returnCode) =>
				return callback err if err
				configuration = @_provider.oauth1.authorize
				placeholderValues = { state: state.id, callback: config.host_url + config.relbase }
				query = @_buildQuery(configuration.query, placeholderValues, opts.options?.authorize)
				query.oauth_token = response.oauth_token
				callback null, @_buildAuthorizeUrl(configuration.url, query, state.id)

	access_token: (state, req, response_type, callback) ->
		if not req.params.oauth_token && not req.params.error
			req.params.error_description ?= 'Authorization refused'

		# manage errors in callback
		if req.params.error || req.params.error_description
			err = new check.Error
			err.error req.params.error_description || 'Error while authorizing'
			err.body.error = req.params.error if req.params.error
			err.body.error_uri = req.params.error_uri if req.params.error_uri
			return callback err

		err = new check.Error
		if @_provider.oauth1.authorize.ignore_verifier == true
			err.check req.params, oauth_token:'string'
		else
			err.check req.params, oauth_token:'string', oauth_verifier:'string'
		return callback err if err.failed()

		configuration = @_provider.oauth1.access_token
		placeholderValues = { state: state.id, callback: config.host_url + config.relbase }
		for extra in (@_provider.oauth1.authorize.extra || [])
			placeholderValues[extra] = req.params[extra] if req.params[extra]
		query = @_buildQuery(configuration.query, placeholderValues)

		headers = {}
		headers["Accept"] = @_short_formats[configuration.format] || configuration.format if configuration.format
		for name, value of configuration.headers
			param = @_replaceParam value, {}
			headers[name] = param if param
		options =
			url: @_replaceParam configuration.url, placeholderValues
			method: configuration.method?.toUpperCase() || "POST"
			encoding: null
			oauth:
				callback: query.oauth_callback
				consumer_key: @_parameters.client_id
				consumer_secret: @_parameters.client_secret
				token: req.params.oauth_token
				token_secret: state.token
		if @_provider.oauth1.authorize.ignore_verifier != true
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
				requestclone[k] = v for k, v of @_provider.oauth1.request
				for k, v of @_params
					if v.scope == 'public'
						requestclone.parameters ?= {}
						requestclone.parameters[k] = @_parameters[k]
				result =
					oauth_token: response.oauth_token
					oauth_token_secret: response.oauth_token_secret
					expires_in: expire
					request: requestclone
				for extra in (configuration.extra||[])
					result[extra] = response.body[extra] if response.body[extra]
				for extra in (@_provider.oauth1.authorize.extra||[])
					result[extra] = req.params[extra] if req.params[extra]
				callback null, result

	request: (req, callback) ->
		if ! @_parameters.oauthio.oauth_token || ! @_parameters.oauthio.oauth_token_secret
			return callback new check.Error "You must provide 'oauth_token' and 'oauth_token_secret' in 'oauthio' http header"

		oauthrequest = @_provider.oauth1.request

		options =
			method: req.method
			followAllRedirects: true

		# build url
		options.url = decodeURIComponent(req.params[1])
		if ! options.url.match(/^[a-z]{2,16}:\/\//)
			if options.url[0] != '/'
				options.url = '/' + options.url
			options.url = oauthrequest.url + options.url
		options.url = @_replaceParam options.url, @_parameters.oauthio

		# build query
		presetQuery = {}
		presetQuery[name] = value for name, value of req.query
		options.qs = @_buildQuery(oauthrequest.query, @_parameters.oauthio, presetQuery)

		options.oauth =
			consumer_key: @_parameters.client_id
			consumer_secret: @_parameters.client_secret
			token: @_parameters.oauthio.oauth_token
			token_secret: @_parameters.oauthio.oauth_token_secret

		# build headers
		options.headers =
			accept:req.headers.accept
			'accept-encoding':req.headers['accept-encoding']
			'accept-language':req.headers['accept-language']
			'content-type':req.headers['content-type']
			'User-Agent': 'OAuth.io'
		for name, value of oauthrequest.headers
			param = @_replaceParam value, @_parameters.oauthio
			options.headers[name] = param if param

		# build body
		if req.method == "PATCH" || req.method == "POST" || req.method == "PUT"
			options.body = req._body || req.body
			delete options.body if typeof options.body == 'object'

		# do request
		callback null, request(options)

module.exports = OAuth1
