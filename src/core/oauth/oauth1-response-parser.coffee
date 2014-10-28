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

module.exports = (env) ->
	check = env.utilities.check
	OAuthResponseParser = require('./oauth-response-parser')(env)

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

	OAuth1ResponseParser