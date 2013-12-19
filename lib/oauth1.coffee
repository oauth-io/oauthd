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
crypto = require 'crypto'

async = require 'async'
request = require 'request'

check = require './check'
db = require './db'
dbstates = require './db_states'
dbproviders = require './db_providers'
dbapps = require './db_apps'
config = require './config'

ksort = (w) ->
	r = {}
	r[k] = w[k] for k in Object.keys(w).sort()
	return r

build_auth_string = (authparams) ->
	"OAuth " + (k + '="' + v + '"' for k,v of ksort authparams).join ","

sign_hmac_sha1 = (method, baseurl, secret, parameters) ->
	data = method + '&' + (encodeURIComponent baseurl) + '&'
	data += encodeURIComponent (k + '=' + v for k,v of ksort parameters).join '&'

	hmacsha1 = crypto.createHmac "sha1", secret
	hmacsha1.update data
	hmacsha1.digest "base64"

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
	params[k] = v for k,v of provider.oauth1.parameters
	dbstates.add
		key:opts.key
		provider:provider.provider
		redirect_uri:opts.redirect_uri
		oauthv:'oauth1'
		origin:opts.origin
		options:opts.options
		expire:600
	, (err, state) ->
		request_token = provider.oauth1.request_token
		query = {}
		if typeof opts.options?.request_token == 'object'
			query = opts.options.request_token
		for name, value of request_token.query
			param = replace_param value, params, state:state.id, callback:config.host_url+config.relbase, parameters
			query[name] = param if param
		headers = {}
		for name, value of request_token.headers
			param = replace_param value, params, {}, parameters
			headers[name] = param if param
		options =
			url: request_token.url
			method: request_token.method?.toUpperCase() || "POST"
			oauth:
				callback: query.oauth_callback
				consumer_key: parameters.client_id
				consumer_secret: parameters.client_secret
		delete query.oauth_callback

		options.headers = headers if Object.keys(headers).length
		if options.method == 'POST'
			options.form = query
		else
			options.qs = query

		# do request to request_token
		request options, (e, r, body) ->
			return callback e if e

			if not body && r.statusCode == 200
				return callback new check.Error 'Http error while requesting request_token (empty response)'

			if body
				if request_token.format == 'json' or r.headers['content-type'] == 'application/json'
					body = JSON.parse(body)
				else if request_token.format == 'url' or r.headers['content-type'] == 'application/x-www-form-urlencoded'
					body = querystring.parse(body)
				else
					try
						body = JSON.parse(body)
					catch err
						try
							body = querystring.parse(body)
						catch err
							err = new check.Error 'Unable to parse body of request_token response'
							err.body.body = body
							return callback err
				if body.error || body.error_description
					err = new check.Error body.error_description || 'Error while requesting token'
					err.body = body
					return callback err

			if r.statusCode != 200
				err = new check.Error 'Http error while requesting token (' + r.statusCode + ')'
				err.body = body
				return callback err

			if not body.oauth_token or not body.oauth_token_secret
				return callback new check.Error 'Could not find request_token in response'

			dbstates.setToken state.id, body.oauth_token_secret, (e, r) ->
				return callback e if e
				authorize = provider.oauth1.authorize
				query = {}
				if typeof opts.options?.authorize == 'object'
					query = opts.options.authorize
				for name, value of authorize.query
					param = replace_param value, params, state:state.id, callback:config.host_url+config.relbase, parameters
					if typeof param != 'string'
						return callback param
					query[name] = param if param
				query.oauth_token = body.oauth_token
				url = replace_param authorize.url, params, {}, parameters
				url += "?" + querystring.stringify query
				callback null, url


exports.access_token = (state, req, callback) ->
	# manage errors in callback
	if req.params.error || req.params.error_description
		err = new check.Error
		err.error req.params.error_description || 'Error while authorizing'
		err.body.error = req.params.error if req.params.error
		err.body.error_uri = req.params.error_uri if req.params.error_uri
		return callback err

	# get infos from state
	async.parallel [
		(callback) -> dbproviders.getExtended state.provider, callback
		(callback) -> dbapps.getKeyset state.key, state.provider, callback
	], (err, res) ->
		return callback err if err
		[provider, {parameters,response_type}] = res
		err = new check.Error
		if provider.oauth1.authorize.ignore_verifier == true
			err.check req.params, oauth_token:'string'
		else
			err.check req.params, oauth_token:'string', oauth_verifier:'string'
		return callback err if err.failed()
		params = {}
		params[k] = v for k,v of provider.parameters
		params[k] = v for k,v of provider.oauth1.parameters

		access_token = provider.oauth1.access_token
		query = {}
		hard_params = state:state.id, callback:config.host_url+config.relbase
		for extra in (provider.oauth1.authorize.extra||[])
			hard_params[extra] = req.params[extra] if req.params[extra]
		for name, value of access_token.query
			param = replace_param value, params, hard_params, parameters
			if typeof param != 'string'
				return callback param
			query[name] = param if param
		options =
			url: replace_param access_token.url, params, hard_params, parameters
			method: access_token.method?.toUpperCase() || "POST"
			oauth:
				callback: query.oauth_callback
				consumer_key: parameters.client_id
				consumer_secret: parameters.client_secret
				token: req.params.oauth_token
				token_secret: state.token
		if provider.oauth1.authorize.ignore_verifier != true
			options.oauth.verifier = req.params.oauth_verifier
		else
			options.oauth.verifier = ""
		delete query.oauth_callback
		if options.method == 'POST'
			options.form = query
		else
			options.qs = query

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
					err.error body.error_description || 'Error while requesting token'
					err.body = body
					return callback err

			if r.statusCode != 200
				err = new check.Error 'Http error while requesting token (' + r.statusCode + ')'
				err.body = body
				return callback err

			if not body.oauth_token
				return callback new check.Error 'Could not find oauth_token in response'
			if not body.oauth_token_secret
				return callback new check.Error 'Could not find oauth_token_secret in response'
			expire = body.expire
			expire ?= body.expires
			expire ?= body.expires_in
			expire ?= body.expires_at
			if expire
				expire = parseInt expire
				now = (new Date).getTime()
				expire -= now if expire > now
			requestclone = {}
			requestclone[k] = v for k, v of provider.oauth1.request
			for k, v of params
				if v.scope == 'public'
					requestclone.parameters ?= {}
					requestclone.parameters[k] = parameters[k]
			result =
				oauth_token: body.oauth_token
				oauth_token_secret: body.oauth_token_secret
				expires_in: expire
				request: requestclone
			for extra in (access_token.extra||[])
				result[extra] = body[extra] if body[extra]
			for extra in (provider.oauth1.authorize.extra||[])
				result[extra] = req.params[extra] if req.params[extra]
			callback null, result

exports.request = (provider, parameters, req, callback) ->
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider.oauth1.parameters

	if ! parameters.oauthio.oauth_token || ! parameters.oauthio.oauth_token_secret
		return callback new check.Error "You must provide 'oauth_token' and 'oauth_token_secret' in 'oauthio' http header"

	oauthrequest = provider.oauth1.request

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

	options.oauth =
		consumer_key: parameters.client_id
		consumer_secret: parameters.client_secret
		token: parameters.oauthio.oauth_token
		token_secret: parameters.oauthio.oauth_token_secret

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
