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

		if not @body.oauth_token or not @body.oauth_token_secret
			return @_setError 'oauth_token or oauth_token_secret not found'

		@oauth_token = @body.oauth_token
		@oauth_token_secret = @body.oauth_token_secret

module.exports = OAuth1ResponseParser