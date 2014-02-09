querystring = require 'querystring'
check = require './check'
OAuthResponseParser = require './oauth-response-parser'

errors_desc =
	authorize:
		'invalid_request': "The request is missing a required parameter, includes an unsupported parameter or parameter value, or is otherwise malformed."
		'invalid_client': "The client identifier provided is invalid."
		'unauthorized_client': "The client is not authorized to use the requested response type."
		'redirect_uri_mismatch': "The redirection URI provided does not match a pre-registered value."
		'access_denied': "The end-user or authorization server denied the request."
		'unsupported_response_type': "The requested response type is not supported by the authorization server."
		'invalid_scope': "The requested scope is invalid, unknown, or malformed."
	access_token:
		'invalid_request': "The request is missing a required parameter, includes an unsupported parameter or parameter value, repeats a parameter, includes multiple credentials, utilizes more than one mechanism for authenticating the client, or is otherwise malformed.",
		'invalid_client': "The client identifier provided is invalid, the client failed to authenticate, the client did not include its credentials, provided multiple client credentials, or used unsupported credentials type.",
		'unauthorized_client': "The authenticated client is not authorized to use the access grant type provided.",
		'invalid_scope': "The requested scope is invalid, unknown, malformed, or exceeds the previously granted scope.",
		'invalid_grant': "The provided access grant is invalid, expired, or revoked (e.g. invalid assertion, expired authorization token, bad end-user password credentials, or mismatching authorization code and redirection URI).",
		'unsupported_grant_type': "The access grant included - its type or another attribute - is not supported by the authorization server."

class OAuth2ResponseParser extends OAuthResponseParser
	constructor: (response, body, format, tokenType) ->
		super response, body, format, tokenType

	parse: (callback) ->
		super (e, r) =>
			if @body?.error or @body?.error_description
				return callback @_setError @body.error_description || errors_desc[@body.error] || 'Error in response'

			return callback e if e

			if not @body.access_token
				return callback @_setError 'access_token not found'

			@access_token = @body.access_token

			callback null, @

OAuth2ResponseParser.errors_desc = errors_desc

module.exports = OAuth2ResponseParser