querystring = require 'querystring'
check = require './check'

module.exports = class
	constructor: (response, body, format) ->
		@_response = response
		@_body = body
		@_format = format
		@_contentType = @_response.headers['content-type']

		if not @_isResponseOk
			@_setError('Error while requesting request_token (HTTP status code: ' + @_response.statusCode + ')')
			return
		if not @_hasBody()
			@_setError('Error while requesting request_token (empty response)')
			return

		if @_isJsonResponse()
			@_parseBodyAsJson()
		if @_isFormResponse()
			@_parseBodyAsForm()
		if @error
			return

		@_parseUnknownBody() if not @_parsedBody
		if not @_hasKeyAndSecret()
			@_setError('Could not find request_token in response')
			return

		@oauth_token = @_parsedBody.oauth_token
		@oauth_token_secret = @_parsedBody.oauth_token_secret

	_isResponseOk: () ->
		return @_response.statusCode == 200

	_hasBody: () ->
		return !!@_body

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
		@_parseBodyAsForm() if not @_parsedBody
		delete @error # this is a fallback, ignore error

	_parseBody: (parseFunc) ->
		try
			@_parsedBody = parseFunc(@_body)
		catch ex
			@_setError('Unable to parse body of request_token response')
			return
		if not @_parsedBody
			return
		if @_parsedBody.error or @_parsedBody.error_description
			@_setError(@_parsedBody.error_description || 'Error while requesting token')
			delete @_parsedBody

	_hasKeyAndSecret: () ->
		return !!@_parsedBody and
		!!@_parsedBody.oauth_token and
		!!@_parsedBody.oauth_token_secret

	_setError: (message) ->
		@_error = new check.Error(message)
		@_error.body = @_body