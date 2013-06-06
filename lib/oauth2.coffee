# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

querystring = require 'querystring'

check = require './check'
dbstates = require './db_states'
config = require './config'

exports.authorize = (provider, keyset, opts, callback) ->
	params = {}
	params[k] = v for k,v of provider.parameters
	params[k] = v for k,v of provider[opts.mode].parameters
	replace_param = (param) ->
		param = param.replace(/\{\{state\}\}/g, 42)
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
