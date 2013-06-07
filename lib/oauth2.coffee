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

exports.authorize = (provider, keyset, opts, callback) ->
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider[opts.oauthv].parameters
	dbstates.add
		key:opts.key
		provider:provider.provider
		redirect_uri:opts.redirect_uri
		oauthv:opts.oauthv
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
	return callback new check.Error 'code', 'unable to find authorize code' if not req.params.code
	async.parallel [
		(callback) -> dbproviders.getExtended state.provider, callback
		(callback) -> dbapps.getKeyset state.key, state.provider, callback
	], (err, res) ->
		[provider, keyset] = res
		params = {}
		params[k] = v for k,v of provider.parameters
		params[k] = v for k,v of provider[state.oauthv].parameters

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
			option.form = qs # or .json = qs for json post

		request options, (e, r, body) ->
			console.log e, body, r.statusCode, r.headers
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

			if r.statusCode != 200
				err = new check.Error 'Http error while requesting access_token (' + r.statusCode + ')'
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
