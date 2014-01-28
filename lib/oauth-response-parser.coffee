querystring = require 'querystring'
check = require './check'

class OAuthResponseParser
	constructor: (response, body, format, tokenType) ->
		@_response = response
		@_unparsedBody = body
		@_format = format || response.headers['content-type']
		@_errorPrefix = 'Error during the \'' + tokenType + '\' step'

		return @_setError 'HTTP status code: ' + response.statusCode if response.statusCode != 200
		return @_setError 'Empty response' if not body

		@_format = @_format.match(/^([^;]+)/)[0] # skip charset etc.
		parseFunc = @_parse[@_format]
		if parseFunc
			@_parseBody parseFunc
		else
			@_parseUnknownBody()

	_parse:
		'application/json': (d) -> JSON.parse d
		'application/x-www-form-urlencoded': (d) -> querystring.parse d

	_parseUnknownBody: ->
		for format, parseFunc of @_parse
			delete @error
			@_parseBody parseFunc
			break if not @error
		@error.message += ' from format ' + @_format if @error
		return

	_parseBody: (parseFunc) ->
		try
			@body = parseFunc(@_unparsedBody)
		catch ex
			return @_setError 'Unable to parse response'
		@_setError 'Empty response' if not @body?
		return

	_setError: (message) ->
		@error = new check.Error @_errorPrefix + ' (' + message + ')'
		if typeof @body == 'object' and Object.keys(@body).length
			@error.body = @body
		else
			@error.body = @_unparsedBody

module.exports = OAuthResponseParser