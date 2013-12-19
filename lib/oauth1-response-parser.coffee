querystring = require 'querystring'
check = require './check'
OAuthResponseParser = require './oauth-response-parser'

class OAuth1ResponseParser extends OAuthResponseParser
	constructor: (response, body, format, tokenType) ->
		super response, body, format, tokenType
		return if @error

		if @body.error or @body.error_description
			@_setError @body.error_description || 'Error in response'
			delete @body

		return @_setError 'oauth_token not found' if not @body.oauth_token
		return @_setError 'oauth_token_secret not found' if not @body.oauth_token_secret?

		@oauth_token = @body.oauth_token
		@oauth_token_secret = @body.oauth_token_secret

module.exports = OAuth1ResponseParser