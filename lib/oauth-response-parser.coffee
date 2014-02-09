querystring = require 'querystring'
check = require './check'
zlib = require 'zlib'

class OAuthResponseParser
	constructor: (response, body, format, tokenType) ->
		@_response = response
		@_undecodedBody = body
		@_format = format || response.headers['content-type']
		@_format = @_format.match(/^([^;]+)/)[0] # skip charset etc.
		@_errorPrefix = 'Error during the \'' + tokenType + '\' step'

	decode: (callback) ->
		if @_response.headers['content-encoding'] == 'gzip'
			zlib.gunzip @_undecodedBody, callback
		else
			callback null, @_undecodedBody

	parse: (callback) ->
		@decode (e, r) =>
			return callback e if e

			@_unparsedBody = r.toString()
			return callback @_setError 'HTTP status code: ' + @_response.statusCode if @_response.statusCode != 200 and not @_unparsedBody
			return callback @_setError 'Empty response' if not @_unparsedBody

			parseFunc = @_parse[@_format]
			if parseFunc
				@_parseBody parseFunc
			else
				@_parseUnknownBody()
			return callback @error if @error
			return callback @_setError 'HTTP status code: ' + @_response.statusCode if @_response.statusCode != 200
			return callback null, @

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
		else if @_unparsedBody
			@error.body = @_unparsedBody
		return @error

module.exports = OAuthResponseParser