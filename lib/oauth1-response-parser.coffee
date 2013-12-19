querystring = require 'querystring'
check = require './check'

class OAuth1ResponseParser
	constructor: (response, body, format, tokenType) ->
		@_response = response
		@_unparsedBody = body
		@_format = format
		@_contentType = @_response.headers['content-type']
		@_errorPrefix = 'Error while parsing \'' + tokenType + '\''
		
		if not @_isResponseOk
			@_setError('HTTP status code: ' + @_response.statusCode)
			return
		if not @_hasBody()
			@_setError('Empty response')
			return

		if @_isJsonResponse()
			@_parseBodyAsJson()
		if @_isFormResponse()
			@_parseBodyAsForm()
		if @error
			return

		@_parseUnknownBody() if not @body
		if not @_hasKeyAndSecret()
			@_setError('oauth_token or oauth_token_secret not found')
			return

		@oauth_token = @body.oauth_token
		@oauth_token_secret = @body.oauth_token_secret

	_isResponseOk: () ->
		return @_response.statusCode == 200

	_hasBody: () ->
		return !!@_unparsedBody

	_isJsonResponse: () ->
		return @_format == 'json' or
		@_contentType == 'application/json'

	_isFormResponse: () ->
		return @_format == 'url' or
		@_contentType == 'application/x-www-form-urlencoded'

	_parseBodyAsJson: () ->
		@_parseBody(JSON.parse)

	_parseBodyAsForm: () ->
		@_parseBody(querystring.parse)

	_parseUnknownBody: () ->
		@_parseBodyAsJson()
		delete @error # this is a fallback, ignore error
		@_parseBodyAsForm() if not @body
		delete @error # this is a fallback, ignore error

	_parseBody: (parseFunc) ->
		try
			@body = parseFunc(@_unparsedBody)
		catch ex
			@_setError('Unable to parse response')
			return
		if not @body
			return
		if @body.error or @body.error_description
			@_setError(@body.error_description || 'Unable to parse response')
			delete @body

	_hasKeyAndSecret: () ->
		return !!@body and
		!!@body.oauth_token and
		!!@body.oauth_token_secret

	_setError: (message) ->
		@error = new check.Error(@_errorPrefix + ' (' + message + ')')
		@error.body = @_unparsedBody

module.exports = OAuth1ResponseParser