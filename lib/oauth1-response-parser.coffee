querystring = require 'querystring'
check = require './check'
OAuthResponseParser = require './oauth-response-parser'

class OAuth1ResponseParser extends OAuthResponseParser
	constructor: (response, body, format, tokenType) ->
		super response, body, format, tokenType

	parse: (callback) ->
		super (e, r) =>
			return callback e if e

			if @body.error or @body.error_description
				return callback @_setError @body.error_description || 'Error in response'

			return callback @_setError 'oauth_token not found' if not @body.oauth_token
			return callback @_setError 'oauth_token_secret not found' if not @body.oauth_token_secret?

			@oauth_token = @body.oauth_token
			@oauth_token_secret = @body.oauth_token_secret

			callback null, @

module.exports = OAuth1ResponseParser