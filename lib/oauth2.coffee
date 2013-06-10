# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

querystring = require 'querystring'

async = require 'async'
request = require 'request'

check = require './check'
dbstates = require './db_states'
dbproviders = require './db_providers'
dbapps = require './db_apps'
config = require './config'

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

exports.authorize = (provider, keyset, opts, callback) ->
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider.oauth2.parameters
	dbstates.add
		key:opts.key
		provider:provider.provider
		redirect_uri:opts.redirect_uri
		oauthv:'oauth2'
		origin:opts.origin
		expire:600
	, (err, state) ->
		replace_param = (param) ->
			param = param.replace(/\{\{state\}\}/g, state.id)
			param = param.replace(/\{\{callback\}\}/g, config.host_url)
			for apiname, apivalue of keyset
				if params[apiname]
					if Array.isArray(apivalue)
						separator = params[apiname].separator
						return new check.Error if not separator
						apivalue = apivalue.join separator
					param = param.replace("{" + apiname + "}", apivalue)
			return param

		authorize = provider.oauth2.authorize
		query = {}
		for name, value of authorize.query
			query[name] = replace_param value
			if typeof query[name] != 'string'
				return callback query[name]
		url = authorize.url
		url += "?" + querystring.stringify query
		callback null, url

exports.access_token = (state, req, callback) ->

	# manage errors in callback
	if req.params.error || req.params.error_description
		err = new check.Error
		if req.params.error_description
			err.error req.params.error_description
		else
			err.error errors_desc.authorize[req.params.error] || 'Error while authorizing'
		err.body.error = req.params.error if req.params.error
		err.body.error_uri = req.params.error_uri if req.params.error_uri
		return callback err
	return callback new check.Error 'code', 'unable to find authorize code' if not req.params.code

	# get infos from state
	async.parallel [
		(callback) -> dbproviders.getExtended state.provider, callback
		(callback) -> dbapps.getKeyset state.key, state.provider, callback
	], (err, res) ->
		[provider, keyset] = res
		params = {}
		params[k] = v for k,v of provider.parameters
		params[k] = v for k,v of provider.oauth2.parameters

		replace_param = (param) ->
			param = param.replace(/\{\{code\}\}/g, req.params.code)
			param = param.replace(/\{\{state\}\}/g, state.id)
			param = param.replace(/\{\{callback\}\}/g, config.host_url)
			for apiname, apivalue of keyset
				if params[apiname]
					if Array.isArray(apivalue)
						separator = params[apiname].separator
						return new check.Error if not separator
						apivalue = apivalue.join separator
					param = param.replace("{" + apiname + "}", apivalue)
			return param

		access_token = provider.oauth2.access_token
		query = {}
		for name, value of access_token.query
			query[name] = replace_param value
			if typeof query[name] != 'string'
				return callback query[name]
		options =
			url: access_token.url
			method: access_token.method?.toUpperCase() || "GET"

		if options.method == "GET"
			options.qs = query
		else
			options.form = query # or .json = qs for json post

		# do request to access_token
		request options, (e, r, body) ->
			return callback e if e

			if not body && r.statusCode == 200
				return callback new check.Error 'Http error while requesting access_token (empty response)'

			if body
				if access_token.format == 'json' or r.headers['content-type'] == 'application/json'
					body = JSON.parse(body)
				else if access_token.format == 'url' or r.headers['content-type'] == 'application/x-www-form-urlencoded'
					body = querystring.parse(body)
				else
					try
						body = JSON.parse(body)
					catch err
						try
							body = querystring.parse(body)
						catch err
							err = new check.Error 'Unable to parse body of access_token response'
							err.body.body = body
							return callback err
				if body.error || body.error_description
					err = new check.Error
					err.error body.error_description || errors_desc.access_token[body.error] || 'Error while requesting token'
					err.body.error = body.error if body.error
					err.body.error_uri = body.error_uri if body.error_uri
					return callback err

			if r.statusCode != 200
				err = new check.Error 'Http error while requesting token (' + r.statusCode + ')'
				err.body = body
				return callback err

			if not body.access_token
				return callback new check.Error 'Could not find access_token in response'
			expire = body.expire
			expire ?= body.expires
			expire ?= body.expires_in
			expire ?= body.expires_at
			if expire
				expire = parseInt expire
				now = (new Date).getTime()
				expire -= now if expire > now
			callback null,
				access_token: body.access_token
				refresh_token: body.refresh_token
				token_type: body.token_type
				expires_in: expire
