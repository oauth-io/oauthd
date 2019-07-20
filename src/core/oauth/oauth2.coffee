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
module.exports = (env) ->
	check = env.utilities.check
	logger = new (env.utilities.logger) "oauth2"

	OAuth2ResponseParser = require('./oauth2-response-parser')(env)
	OAuthBase = require('./oauth-base')(env)

	class OAuth2 extends OAuthBase
		constructor: (provider, parameters) ->
			super 'oauth2', provider, parameters

		authorize: (opts, callback) ->
			@_createState opts, (err, state) =>
				return callback err if err
				configuration = @_oauthConfiguration.authorize
				if not configuration.url?
					return callback new Error('The provider is not properly configured internally. Please contact the provider owner if available.')
				placeholderValues = { state: state.id, callback: @_serverCallbackUrl }
				if opts.options?.scope
					@_parameters['scope'] = opts.options.scope
				query = @_buildQuery(configuration.query, placeholderValues, opts.options?.authorize)
				callback null, @_buildAuthorizeUrl(configuration.url, query, state.id)

		access_token: (state, req, callback) ->
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

			configuration = @_oauthConfiguration.access_token
			placeholderValues = { code: req.params.code, state: state.id, callback: @_serverCallbackUrl }
			@_setExtraRequestAuthorizeParameters(req, placeholderValues)
			query = @_buildQuery(configuration.query, placeholderValues)
			headers = @_buildHeaders(configuration)
			options = @_buildRequestOptions(configuration, headers, query, placeholderValues)
			options.followAllRedirects = true

			# do request to access_token
			request options, (e, r, body) =>
				return callback(e) if e
				responseParser = new OAuth2ResponseParser(r, body, headers["Accept"], 'access_token')
				responseParser.parse (err, response) =>
					return callback err if err

					expire = @_getExpireParameter(response)
					requestclone = @_cloneRequest()
					result =
						access_token: response.access_token
						token_type: response.body.token_type
						id_token: response.body.id_token
						expires_in: expire
						base: @_provider.baseurl
						request: requestclone
						refresh_token: response.body.refresh_token
					@_setExtraResponseParameters(configuration, response, result)
					@_setExtraRequestAuthorizeParameters(req, result)
					callback null, result

		refresh: (token, keyset, callback) ->
			configuration = @_oauthConfiguration.refresh
			placeholderValues = { refresh_token: token }
			query = @_buildQuery(configuration.query, placeholderValues)
			headers = @_buildHeaders(configuration, { refresh_token: token })
			options = @_buildRequestOptions(configuration, headers, query)
			options.followAllRedirects = true

			# request new token
			request options, (e, r, body) =>
				return callback e if e

				responseParser = new OAuth2ResponseParser(r, body, headers["Accept"], 'refresh token')
				responseParser.parse (err, response) =>
					return callback err if err

					expire = @_getExpireParameter(response)
					result =
						access_token: response.body.access_token
						token_type: response.body.token_type
						expires_in: expire
					if response.body.refresh_token && (@_appOptions.refresh_client || keyset.response_type == "code")
						result.refresh_token = response.body.refresh_token
					callback null, result

		request: (req, callback) ->
			if ! @_parameters.oauthio.token
				if @_parameters.oauthio.access_token
					@_parameters.oauthio.token = @_parameters.oauthio.access_token
				else
					return callback new check.Error "You must provide a 'token' in 'oauthio' http header"

			configuration = @_provider.oauth2.request
			options = @_buildServerRequestOptions(req, configuration)

			# do request
			callback null, options

	return OAuth2
