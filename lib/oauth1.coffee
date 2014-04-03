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
db = require './db'

OAuth1ResponseParser = require './oauth1-response-parser'
OAuthBase = require './oauth-base'

class OAuth1 extends OAuthBase
	constructor: (provider, parameters) ->
		super 'oauth1', provider, parameters

	authorize: (opts, callback) ->
		@_createState opts, (err, state) =>
			return callback err if err
			@_getRequestToken state, opts, callback

	_getRequestToken: (state, opts, callback) ->
		configuration = @_oauthConfiguration.request_token
		placeholderValues = { state: state.id, callback: @_serverCallbackUrl }
		query = @_buildQuery(configuration.query, placeholderValues, opts.options?.request_token)
		headers = @_buildHeaders(configuration)
		options = @_buildRequestOptions(configuration, headers, query)
		options.oauth = {
			callback: query.oauth_callback
			consumer_key: @_parameters.client_id
			consumer_secret: @_parameters.client_secret
		}
		delete query.oauth_callback

		# do request to request_token
		request options, (err, response, body) =>
			return callback err if err
			@_parseGetRequestTokenResponse(response, body, opts, headers, state, callback)

	_parseGetRequestTokenResponse: (response, body, opts, headers, state, callback) ->
		responseParser = new OAuth1ResponseParser(response, body, headers["Accept"], 'request_token')
		responseParser.parse (err, response) =>
			return callback err if err
			db.states.setToken state.id, response.oauth_token_secret, (err, returnCode) =>
				return callback err if err
				configuration = @_oauthConfiguration.authorize
				placeholderValues = { state: state.id, callback: @_serverCallbackUrl }
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
		if @_oauthConfiguration.authorize.ignore_verifier == true
			err.check req.params, oauth_token:'string'
		else
			err.check req.params, oauth_token:'string', oauth_verifier:'string'
		return callback err if err.failed()

		configuration = @_oauthConfiguration.access_token
		placeholderValues = { state: state.id, callback: @_serverCallbackUrl }
		@_setExtraRequestAuthorizeParameters(req, placeholderValues)
		query = @_buildQuery(configuration.query, placeholderValues)
		headers = @_buildHeaders(configuration)
		options = @_buildRequestOptions(configuration, headers, query)
		options.oauth = {
			callback: query.oauth_callback
			consumer_key: @_parameters.client_id
			consumer_secret: @_parameters.client_secret
			token: req.params.oauth_token
			token_secret: state.token
		}
		if @_oauthConfiguration.authorize.ignore_verifier != true
			options.oauth.verifier = req.params.oauth_verifier
		else
			options.oauth.verifier = ''
		delete query.oauth_callback

		# do request to access_token
		request options, (e, r, body) =>
			return callback(e) if e
			responseParser = new OAuth1ResponseParser(r, body, headers["Accept"], 'access_token')
			responseParser.parse (err, response) =>
				return callback err if err

				expire = @_getExpireParameter(response)
				requestclone = @_cloneRequest()
				result =
					oauth_token: response.oauth_token
					oauth_token_secret: response.oauth_token_secret
					expires_in: expire
					request: requestclone
				@_setExtraResponseParameters(configuration, response, result)
				@_setExtraRequestAuthorizeParameters(req, result)
				callback null, result

	request: (req, callback) ->
		if ! @_parameters.oauthio.oauth_token || ! @_parameters.oauthio.oauth_token_secret
			return callback new check.Error "You must provide 'oauth_token' and 'oauth_token_secret' in 'oauthio' http header"

		options = @_buildServerRequestOptions(req)
		options.oauth =
			consumer_key: @_parameters.client_id
			consumer_secret: @_parameters.client_secret
			token: @_parameters.oauthio.oauth_token
			token_secret: @_parameters.oauthio.oauth_token_secret

		# do request
		callback null, options

module.exports = OAuth1
