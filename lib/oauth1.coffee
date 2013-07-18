# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

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
	"OAuth " + (k + '="' + v + '"' for k,v of authparams).join ","

sign_hmac_sha1 = (method, baseurl, secret, parameters) ->
	data = method + '&' + (encodeURIComponent baseurl) + '&'
	data += encodeURIComponent (k + '=' + v for k,v of ksort parameters).join '&'

	hmacsha1 = crypto.createHmac "sha1", secret
	hmacsha1.update data
	hmacsha1.digest "base64"

exports.authorize = (provider, keyset, opts, callback) ->
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

		request_token = provider.oauth1.request_token
		query = {}
		if typeof opts.options?.authorize == 'object'
			query = opts.options.authorize
		for name, value of request_token.query
			query[name] = replace_param value
			if typeof query[name] != 'string'
				return callback query[name]
		options =
			url: request_token.url
			method: 'POST'

		query.oauth_nonce = db.generateUid()
		query.oauth_timestamp = Math.floor new Date / 1000
		query.oauth_version = "1.0"
		query.oauth_callback = encodeURIComponent query.oauth_callback
		if not query.oauth_signature_method
			query.oauth_signature_method = 'HMAC-SHA1'
		else
			query.oauth_signature_method = query.oauth_signature_method.toUpperCase()
		if query.oauth_signature_method == 'HMAC-SHA1'
			query.oauth_signature = encodeURIComponent sign_hmac_sha1('POST', options.url, keyset.client_secret + '&', query)
		else
			return callback new check.Error 'Unknown signature method'
		options.form = {}
		options.headers = Authorization: build_auth_string query

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
				for name, value of authorize.query
					query[name] = replace_param value
					if typeof query[name] != 'string'
						return callback query[name]
				query.oauth_token = body.oauth_token
				url = authorize.url
				url += "?" + querystring.stringify query
				callback null, url


#    this.saveToken(api, oauth_tokens);
#


exports.access_token = (state, req, callback) ->
	# manage errors in callback
	if req.params.error || req.params.error_description
		err = new check.Error
		err.error req.params.error_description || 'Error while authorizing'
		err.body.error = req.params.error if req.params.error
		err.body.error_uri = req.params.error_uri if req.params.error_uri
		return callback err
	err = new check.Error
	err.check req.params, oauth_token:'string', oauth_verifier:'string'
	return callback err if err.failed()

	# get infos from state
	async.parallel [
		(callback) -> dbproviders.getExtended state.provider, callback
		(callback) -> dbapps.getKeyset state.key, state.provider, callback
	], (err, res) ->
		[provider, keyset] = res
		params = {}
		params[k] = v for k,v of provider.parameters
		params[k] = v for k,v of provider.oauth1.parameters

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

		access_token = provider.oauth1.access_token
		query = {}
		for name, value of access_token.query
			query[name] = replace_param value
			if typeof query[name] != 'string'
				return callback query[name]
		options =
			url: access_token.url
			method: 'POST'

		query.oauth_nonce = db.generateUid()
		query.oauth_timestamp = Math.floor new Date / 1000
		query.oauth_version = "1.0"
		query.oauth_token = req.params.oauth_token
		query.oauth_verifier = req.params.oauth_verifier
		if not query.oauth_signature_method
			query.oauth_signature_method = 'HMAC-SHA1'
		else
			query.oauth_signature_method = query.oauth_signature_method.toUpperCase()
		if query.oauth_signature_method == 'HMAC-SHA1'
			query.oauth_signature = encodeURIComponent sign_hmac_sha1('POST', options.url, keyset.client_secret + '&' + state.token, query)
		else
			return callback new check.Error 'Unknown signature method'
		options.form = {}
		options.headers = Authorization: build_auth_string query

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
			callback null,
				oauth_token: body.oauth_token
				oauth_token_secret: body.oauth_token_secret
				expires_in: expire
