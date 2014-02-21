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

request = require 'request'
check = require './check'

OAuth2ResponseParser = require './oauth2-response-parser'
OAuthBase = require './oauth-base'

class OAuth2 extends OAuthBase
	constructor: (provider, parameters) ->
		super 'oauth2', provider, parameters

	authorize: (opts, callback) ->
		@_createState @_provider, opts, (err, state) =>
			return callback err if err
			configuration = @_provider.oauth2.authorize
			placeholderValues = { state: state.id, callback: @_serverCallbackUrl }
			query = @_buildQuery(configuration.query, placeholderValues, opts.options?.authorize)
			callback null, @_buildAuthorizeUrl(configuration.url, query, state.id)

	access_token: (state, req, response_type, callback) ->
		# manage errors in callback
		if req.params.error || req.params.error_description
			err = new check.Error
			if req.params.error_description
				err.error req.params.error_description
			else
				err.error OAuth2ResponseParser.errors_desc.authorize[req.params.error] || 'Error while authorizing'
			err.body.error = req.params.error if req.params.error
			err.body.error_uri = req.params.error_uri if req.params.error_uri
			return callback err
		return callback new check.Error 'code', 'unable to find authorize code' if not req.params.code

		configuration = @_provider.oauth2.access_token
		placeholderValues = { code: req.params.code, state: state.id, callback: @_serverCallbackUrl }
		query = @_buildQuery(configuration.query, placeholderValues)

		headers = {}
		headers["Accept"] = @_short_formats[configuration.format] || configuration.format if configuration.format
		for name, value of configuration.headers
			param = @_replaceParam value, {}
			headers[name] = param if param
		options =
			url: @_replaceParam configuration.url, {}
			method: configuration.method?.toUpperCase() || "POST"
			followAllRedirects: true
			encoding: null

		options.headers = headers if Object.keys(headers).length
		if options.method == "GET"
			options.qs = query
		else
			options.form = query # or .json = qs for json post

		# do request to access_token
		request options, (e, r, body) =>
			return callback e if e
			responseParser = new OAuth2ResponseParser(r, body, headers["Accept"], 'access_token')
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
				requestclone[k] = v for k, v of @_provider.oauth2.request
				for k, v of @_params
					if v.scope == 'public'
						requestclone.parameters ?= {}
						requestclone.parameters[k] = @_parameters[k]
				result =
					access_token: response.access_token
					token_type: response.body.token_type
					expires_in: expire
					base: @_provider.baseurl
					request: requestclone
				result.refresh_token = response.body.refresh_token if response.body.refresh_token && response_type == "code"
				for extra in (configuration.extra||[])
					result[extra] = response.body[extra] if response.body[extra]
				for extra in (@_provider.oauth2.authorize.extra||[])
					result[extra] = req.params[extra] if req.params[extra]
				callback null, result

	refresh: (token, callback) ->
		configuration = @_provider.oauth2.refresh
		placeholderValues = { refresh_token: token }
		query = @_buildQuery(configuration.query, placeholderValues)

		headers = {}
		headers["Accept"] = @_short_formats[configuration.format] || configuration.format if configuration.format
		for name, value of configuration.headers
			param = @_replaceParam value, { refresh_token: token }
			headers[name] = param if param
		options =
			url: @_replaceParam configuration.url, {}
			method: configuration.method?.toUpperCase() || "POST"
			followAllRedirects: true

		options.headers = headers if Object.keys(headers).length
		if options.method == "GET"
			options.qs = query
		else
			options.form = query # or .json = qs for json post

		# request new token
		request options, (e, r, body) =>
			return callback e if e
			responseParser = new OAuth2ResponseParser(r, body, headers["Accept"], 'refresh token')
			responseParser.parse (err, response) ->
				return callback err if err

				expire = response.body.expire
				expire ?= response.body.expires
				expire ?= response.body.expires_in
				expire ?= response.body.expires_at
				if expire
					expire = parseInt expire
					now = (new Date).getTime()
					expire -= now if expire > now
				result =
					access_token: response.access_token
					token_type: response.body.token_type
					expires_in: expire
				result.refresh_token = response.body.refresh_token if response.body.refresh_token && keyset.response_type == "code"
				callback null, result

	request: (req, callback) ->
		if ! @_parameters.oauthio.token
			if @_parameters.oauthio.access_token
				@_parameters.oauthio.token = @_parameters.oauthio.access_token
			else
				return callback new check.Error "You must provide a 'token' in 'oauthio' http header"

		oauthrequest = @_provider.oauth2.request

		options =
			method: req.method
			followAllRedirects: true
			encoding: null

		options.url = @_buildServerRequestUrl(req.params[1], oauthrequest.url)
		options.qs = @_buildServerRequestQuery(req.query, oauthrequest.query)
		options.headers = @_buildServerRequestHeaders(req.headers, oauthrequest.headers)

		# build body
		if req.method == "PATCH" || req.method == "POST" || req.method == "PUT"
			options.body = req._body || req.body
			delete options.body if typeof options.body == 'object'

		# do request
		callback null, request(options)

module.exports = OAuth2
