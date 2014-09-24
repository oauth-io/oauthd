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

querystring = require 'querystring'

zlib = require 'zlib'

module.exports = (env) ->
	check = env.engine.check
	
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

	OAuthResponseParser