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

replace_param = (param, params, hard_params, keyset) ->
	param = param.replace /\{\{(.*?)\}\}/g, (match, val) ->
		return hard_params[val] || ""
	return param.replace /\{(.*?)\}/g, (match, val) ->
		return "" if ! params[val] || ! keyset[val]
		if Array.isArray(keyset[val])
			return keyset[val].join params[val].separator || ","
		return keyset[val]

exports.authorize = (provider, parameters, opts, callback) ->
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider.oauth2.parameters
	dbstates.add
		key:opts.key
		provider:provider.provider
		redirect_uri:opts.redirect_uri
		oauthv:'oauth2'
		origin:opts.origin
		options:opts.options
		expire:600
	, (err, state) ->
		authorize = provider.oauth2.authorize
		query = {}
		if typeof opts.options?.authorize == 'object'
			query = opts.options.authorize
		for name, value of authorize.query
			param = replace_param value, params, state:state.id, callback:config.host_url+config.relbase, parameters
			if typeof param != 'string'
				return callback param
			query[name] = param if param
		url = replace_param authorize.url, params, {}, parameters
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
		return callback err if err
		[provider, {parameters,response_type}] = res
		params = {}
		params[k] = v for k,v of provider.parameters
		params[k] = v for k,v of provider.oauth2.parameters

		access_token = provider.oauth2.access_token
		query = {}
		for name, value of access_token.query
			param = replace_param value, params, code:req.params.code, state:state.id, callback:config.host_url+config.relbase, parameters
			if typeof param != 'string'
				return callback param
			query[name] = param if param
		options =
			url: replace_param access_token.url, params, {}, parameters
			method: access_token.method?.toUpperCase() || "POST"
			followAllRedirects: true

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
					err.body = body
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
			requestclone = {}
			requestclone[k] = v for k, v of provider.oauth2.request
			for k, v of params
				if v.scope == 'public'
					requestclone.parameters ?= {}
					requestclone.parameters[k] = parameters[k]
			result =
				access_token: body.access_token
				token_type: body.token_type
				expires_in: expire
				base: provider.baseurl
				request: requestclone
			result.refresh_token = body.refresh_token if body.refresh_token && response_type == "code"
			for extra in (access_token.extra||[])
				result[extra] = body[extra] if body[extra]
			for extra in (provider.oauth2.authorize.extra||[])
				result[extra] = req.params[extra] if req.params[extra]
			callback null, result

exports.refresh = (keyset, provider, token, callback) ->
	parameters = keyset.parameters
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider.oauth2.parameters

	refresh = provider.oauth2.refresh
	query = {}
	for name, value of refresh.query
		param = replace_param value, params, refresh_token:token, parameters
		if typeof param != 'string'
			return callback param
		query[name] = param if param
	options =
		url: replace_param refresh.url, params, {}, parameters
		method: refresh.method?.toUpperCase() || "POST"
		followAllRedirects: true

	if options.method == "GET"
		options.qs = query
	else
		options.form = query # or .json = qs for json post

	# request new token
	request options, (e, r, body) ->
		return callback e if e

		if not body && r.statusCode == 200
			return callback new check.Error 'Http error while requesting new token (empty response)'

		if body
			if refresh.format == 'json' or r.headers['content-type'] == 'application/json'
				body = JSON.parse(body)
			else if refresh.format == 'url' or r.headers['content-type'] == 'application/x-www-form-urlencoded'
				body = querystring.parse(body)
			else
				try
					body = JSON.parse(body)
				catch err
					try
						body = querystring.parse(body)
					catch err
						err = new check.Error 'Unable to parse body of refresh token response'
						err.body.body = body
						return callback err
			if body.error || body.error_description
				err = new check.Error
				err.error body.error_description || errors_desc.access_token[body.error] || 'Error while requesting new token'
				err.body = body
				return callback err

		if r.statusCode != 200
			err = new check.Error 'Http error while requesting new token (' + r.statusCode + ')'
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
		result =
			access_token: body.access_token
			token_type: body.token_type
			expires_in: expire
		result.refresh_token = body.refresh_token if body.refresh_token && keyset.response_type == "code"
		callback null, result

exports.request = (provider, parameters, req, callback) ->
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider.oauth2.parameters

	if ! parameters.oauthio.token
		return callback new check.Error "You must provide a 'token' in 'oauthio' http header"

	oauthrequest = provider.oauth2.request

	options =
		method: req.method
		followAllRedirects: true

	# build url
	options.url = decodeURIComponent(req.params[1])
	if ! options.url.match(/^[a-z]{2,16}:\/\//)
		if options.url[0] != '/'
			options.url = '/' + options.url
		options.url = oauthrequest.url + options.url
	options.url = replace_param options.url, params, parameters.oauthio, parameters

	# build query
	options.qs = {}
	options.qs[name] = value for name, value of req.query
	for name, value of oauthrequest.query
		param = replace_param value, params, parameters.oauthio, parameters
		if typeof param != 'string'
			return callback param
		options.qs[name] = param if param

	# build headers
	options.headers =
		accept:req.headers.accept
		'accept-encoding':req.headers['accept-encoding']
		'accept-language':req.headers['accept-language']
		'content-type':req.headers['content-type']
	for name, value of oauthrequest.headers
		param = replace_param value, params, parameters.oauthio, parameters
		if typeof param != 'string'
			return callback param
		options.headers[name] = param if param

	# build body
	if req.method == "PATCH" || req.method == "POST" || req.method == "PUT"
		options.body = req._body || req.body

	# do request
	callback null, request(options)
