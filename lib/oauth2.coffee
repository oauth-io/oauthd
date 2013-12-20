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

OAuth2ResponseParser = require './oauth2-response-parser'
short_formats = OAuth2ResponseParser.short_formats

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
			param = replace_param value, params, state:state.id, callback:config.host_url+config.base, parameters
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
			err.error OAuth2ResponseParser.errors_desc.authorize[req.params.error] || 'Error while authorizing'
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
			param = replace_param value, params, code:req.params.code, state:state.id, callback:config.host_url+config.base, parameters
			query[name] = param if param
		headers = {}
		headers["Accept"] = short_formats[access_token.format] || access_token.format if access_token.format
		for name, value of access_token.headers
			param = replace_param value, params, {}, parameters
			headers[name] = param if param
		options =
			url: replace_param access_token.url, params, {}, parameters
			method: access_token.method?.toUpperCase() || "POST"
			followAllRedirects: true

		options.headers = headers if Object.keys(headers).length
		if options.method == "GET"
			options.qs = query
		else
			options.form = query # or .json = qs for json post

		# do request to access_token
		request options, (e, r, body) ->
			return callback e if e
			responseParser = new OAuth2ResponseParser(r, body, headers["Accept"], 'access_token')
			return callback(responseParser.error) if responseParser.error

			expire = responseParser.body.expire
			expire ?= responseParser.body.expires
			expire ?= responseParser.body.expires_in
			expire ?= responseParser.body.expires_at
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
				access_token: responseParser.access_token
				token_type: responseParser.body.token_type
				expires_in: expire
				base: provider.baseurl
				request: requestclone
			result.refresh_token = responseParser.body.refresh_token if responseParser.body.refresh_token && response_type == "code"
			for extra in (access_token.extra||[])
				result[extra] = responseParser.body[extra] if responseParser.body[extra]
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
		query[name] = param if param
	headers = {}
	headers["Accept"] = short_formats[refresh.format] || refresh.format if refresh.format
	for name, value of refresh.headers
		param = replace_param value, params, refresh_token:token, parameters
		headers[name] = param if param
	options =
		url: replace_param refresh.url, params, {}, parameters
		method: refresh.method?.toUpperCase() || "POST"
		followAllRedirects: true

	options.headers = headers if Object.keys(headers).length
	if options.method == "GET"
		options.qs = query
	else
		options.form = query # or .json = qs for json post

	# request new token
	request options, (e, r, body) ->
		return callback e if e
		responseParser = new OAuth2ResponseParser(r, body, headers["Accept"], 'refresh token')
		return callback(responseParser.error) if responseParser.error

		expire = responseParser.body.expire
		expire ?= responseParser.body.expires
		expire ?= responseParser.body.expires_in
		expire ?= responseParser.body.expires_at
		if expire
			expire = parseInt expire
			now = (new Date).getTime()
			expire -= now if expire > now
		result =
			access_token: responseParser.body.access_token
			token_type: responseParser.body.token_type
			expires_in: expire
		result.refresh_token = responseParser.body.refresh_token if responseParser.body.refresh_token && keyset.response_type == "code"
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
		options.qs[name] = param if param

	# build headers
	options.headers =
		accept:req.headers.accept
		'accept-encoding':req.headers['accept-encoding']
		'accept-language':req.headers['accept-language']
		'content-type':req.headers['content-type']
	for name, value of oauthrequest.headers
		param = replace_param value, params, parameters.oauthio, parameters
		options.headers[name] = param if param

	# build body
	if req.method == "PATCH" || req.method == "POST" || req.method == "PUT"
		options.body = req._body || req.body

	# do request
	callback null, request(options)
