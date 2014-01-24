# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
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

rootdir = __dirname + '/..'

fs = require 'fs'
Url = require 'url'
async = require 'async'
JaySchema = require 'jayschema'
jsonlint = require 'jsonlint'

jsonlint.parser.parseError = jsonlint.parser.lexer.parseError = (str, hash) ->
	throw new Error "Parse error at #{hash.loc.first_line}:#{hash.loc.last_column}, found: '#{hash.token}' - expected: " + hash.expected.join(', ') + '.'

jay = new JaySchema
jay.register require './provider_schema'

styles = require './console_styles'

styles.ctx = (instanceContext) ->
	res = instanceContext.substr(2).split '/'
	res[res.length - 1] = styles.wrap('red', res[res.length - 1])
	return res.join '.'

styles.enum = (arr) ->
	return "'" + arr[0] + "'" if arr.length == 1
	return "'" + arr[0] + "' or '" + arr[1] + "'" if arr.length == 2
	if arr.length > 2
		lastelt = arr.pop()
		return "'" + arr.join("', '") + "'" + "', or '" + lastelt + "'"

class ProviderError extends Error
	constructor: (msg, infos) ->
		@provider = infos.provider
		super(msg)
		@message = msg

class ProviderWarning extends Error
	constructor: (msg, infos) ->
		@provider = infos.provider
		super(msg)
		@message = msg

checkOAuth1 = (provider, data, root, errors) ->
	checkParameters provider, data.parameters, '#/oauth1/parameters', errors if data.parameters

	# oauth1.request_token checks
	if typeof data.request_token == 'object'
		a = data.request_token
		if a.query && a.query.oauth_consumer_key == "{client_id}" && a.query.oauth_callback == "{{callback}}" &&
			Object.keys(a.query).length == 2
				errors.push new ProviderWarning styles.ctx('#/oauth1/request_token/query') + ' can be removed (using default)', provider:provider
				delete a.query
		if a.url && Object.keys(a).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth1/request_token') + ' can be compacted as request_token.url', provider:provider

	# oauth1.authorize checks
	if typeof data.authorize == 'object'
		a = data.authorize
		if a.ignore_verifier == false
			errors.push new ProviderWarning styles.ctx('#/oauth1/authorize/ignore_verifier') + ' can be removed (using default)', provider: provider
		if a.ignore_verifier == true && a.query?.oauth_callback == '{{callback}}' && Object.keys(a.query).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth1/authorize/query') + ' can be removed (using default) with ignore_verifier=true', provider:provider
		if a.url && Object.keys(a).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth1/authorize') + ' can be compacted as authorize.url', provider:provider

	# oauth1.access_token checks
	if typeof data.access_token == 'object'
		a = data.access_token
		if a.query && a.query.oauth_consumer_key == "{client_id}" && Object.keys(a.query).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth1/access_token/query') + ' can be removed (using default)', provider:provider
			delete a.query
		if a.url && Object.keys(a).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth1/access_token') + ' can be compacted as access_token.url', provider:provider

	# oauth1.request checks
	request_url = data.request
	if typeof data.request == 'object'
		a = data.request
		request_url = a.url
		if a.url
			rooturl = Url.parse(root.url || '')
			aurl = Url.parse(a.url)
			if rooturl.protocol == aurl.protocol && rooturl.host == aurl.host
				if Object.keys(a).length == 1
					errors.push new ProviderWarning styles.ctx('#/oauth1/request') + ' can be removed (using default)', provider:provider
				else
					errors.push new ProviderWarning styles.ctx('#/oauth1/request/url') + ' can be removed (using default)', provider:provider
			else if Object.keys(a).length == 1
					errors.push new ProviderWarning styles.ctx('#/oauth1/request') + ' can be compacted as request.url', provider:provider
	else if request_url
		aurl = Url.parse(request_url)
		rooturl = Url.parse(root.url || '')
		if rooturl.protocol == aurl.protocol && rooturl.host == aurl.host
			errors.push new ProviderWarning styles.ctx('#/oauth1/request') + ' can be removed (using default)', provider:provider
	if request_url
		aurl = Url.parse(request_url.replace /\{\{.+?\}\}/g, "")
		if aurl.path != '/' && aurl.path || aurl.hash
			errors.push new ProviderWarning styles.ctx('#/oauth1/request/url') + ' should not contain a path or hash', provider:provider

checkOAuth2 = (provider, data, root, errors) ->
	checkParameters provider, data.parameters, '#/oauth2/parameters', errors if data.parameters

	# oauth2.authorize checks
	if typeof data.authorize == 'object'
		a = data.authorize
		if a.query && a.query.client_id == "{client_id}" && a.query.response_type == "code" &&
			a.query.redirect_uri == "{{callback}}" && a.query.state == "{{state}}" &&
			(Object.keys(a.query).length == 4 || a.query.scope == "{scope}" && Object.keys(a.query).length == 5)
				errors.push new ProviderWarning styles.ctx('#/oauth2/authorize/query') + ' can be removed (using default)', provider:provider
				delete a.query
		if a.url && Object.keys(a).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth2/authorize') + ' can be compacted as authorize.url', provider:provider

	# oauth2.access_token checks
	if typeof data.access_token == 'object'
		a = data.access_token
		if a.query && a.query.client_id == "{client_id}" && a.query.client_secret == "{client_secret}" &&
			a.query.redirect_uri == "{{callback}}" && a.query.grant_type == "authorization_code" &&
			a.query.code == "{{code}}" && Object.keys(a.query).length == 5
				errors.push new ProviderWarning styles.ctx('#/oauth2/access_token/query') + ' can be removed (using default)', provider:provider
				delete a.query
		if a.method == 'post'
			errors.push new ProviderWarning styles.ctx('#/oauth2/access_token/method') + ' can be removed (using default)', provider:provider
			delete a.method
		if a.url && Object.keys(a).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth2/access_token') + ' can be compacted as access_token.url', provider:provider

	# oauth2.request checks
	request_url = data.request
	if typeof data.request == 'object'
		a = data.request
		request_url = a.url
		if a.headers && a.headers.Authorization == "Bearer {{token}}" && Object.keys(a.headers).length == 1 &&
			not (a.query && Object.keys(a.query).length)
				errors.push new ProviderWarning styles.ctx('#/oauth2/request/headers') + ' can be removed (using default)', provider:provider
				delete a.headers
		if a.url
			rooturl = Url.parse(root.url || '')
			aurl = Url.parse(a.url)
			if rooturl.protocol == aurl.protocol && rooturl.host == aurl.host
				if Object.keys(a).length == 1
					errors.push new ProviderWarning styles.ctx('#/oauth2/request') + ' can be removed (using default)', provider:provider
				else
					errors.push new ProviderWarning styles.ctx('#/oauth2/request/url') + ' can be removed (using default)', provider:provider
			else if Object.keys(a).length == 1
				errors.push new ProviderWarning styles.ctx('#/oauth2/request') + ' can be compacted as request.url', provider:provider
	else if request_url
		aurl = Url.parse(request_url)
		rooturl = Url.parse(root.url || '')
		if rooturl.protocol == aurl.protocol && rooturl.host == aurl.host
			errors.push new ProviderWarning styles.ctx('#/oauth2/request') + ' can be removed (using default)', provider:provider
	if request_url
		aurl = Url.parse(request_url.replace /\{\{.+?\}\}/g, "")
		if aurl.path != '/' && aurl.path || aurl.hash
			errors.push new ProviderWarning styles.ctx('#/oauth2/request/url') + ' should not contain a path or hash', provider:provider

	# oauth2.refresh checks
	if typeof data.refresh == 'object'
		a = data.refresh
		if a.query && a.query.client_id == "{client_id}" && a.query.client_secret == "{client_secret}" &&
			a.query.refresh_token == "{{refresh_token}}" && a.query.grant_type == "refresh_token" &&
			Object.keys(a.query).length == 4
				errors.push new ProviderWarning styles.ctx('#/oauth2/refresh/query') + ' can be removed (using default)', provider:provider
				delete a.query
		if a.method == 'post'
			errors.push new ProviderWarning styles.ctx('#/oauth2/refresh/method') + ' can be removed (using default)', provider:provider
			delete a.method
		if a.url && Object.keys(a).length == 1
			errors.push new ProviderWarning styles.ctx('#/oauth2/refresh') + ' can be compacted as refresh.url', provider:provider

checkParameters = (provider, data, ref, errors) ->
	for name, param of data
		if typeof param == 'object'
			if param.separator == ' '
				errors.push new ProviderWarning styles.ctx(ref + '/' + name + '/separator') + ' can be removed (using default)', provider:provider
			if param.cardinality == '*'
				errors.push new ProviderWarning styles.ctx(ref + '/' + name + '/cardinality') + ' can be removed (using default)', provider:provider
			if param.type == 'string'
				errors.push new ProviderWarning styles.ctx(ref + '/' + name + '/type') + ' can be removed (using default)', provider:provider

checkHref = (provider, data, errors) ->
	errors.push new ProviderWarning styles.ctx('#/href/provider') + ' should be present', provider:provider if not data.provider
	errors.push new ProviderWarning styles.ctx('#/href/keys') + ' should be present', provider:provider if not data.keys
	errors.push new ProviderWarning styles.ctx('#/href/apps') + ' should be present', provider:provider if not data.apps
	errors.push new ProviderWarning styles.ctx('#/href/docs') + ' should be present', provider:provider if not data.docs

checkProvider = (provider, data, errors) ->
	# json parsing
	try
		data = jsonlint.parse data.toString()
	catch e
		errors.push new ProviderError e.message, provider:provider
		errors.push new ProviderError 'Stoping at check step 1/3', provider:provider
		return

	errs = jay.validate(data, "https://oauth.io/provider-schema#")

	errors_count = 0
	while errs.length
		errors_count += errs.length
		new_errs = []
		for err in errs
			if err.constraintName == "oneOf" && err.kind == "SubSchemaValidationError" && Object.keys(err.subSchemaValidationErrors).length == 1
				err = err.subSchemaValidationErrors[Object.keys(err.subSchemaValidationErrors)[0]]
				errors_count--
				new_errs.push e for e in err
			else if err.constraintName == "additionalProperties"
				errors.push new ProviderWarning "Unknown field " + styles.ctx(err.instanceContext + '/' + err.testedValue), provider:provider
				errors_count--
			else if err.constraintName == "enum"
				errors.push new ProviderError styles.ctx(err.instanceContext) + " must be " + styles.enum(err.constraintValue), provider:provider
			else if err.constraintName == "required"
				errors.push new ProviderError "Missing field " + styles.ctx(err.instanceContext + '/' + err.desc.substr(9)), provider:provider
			else if err.constraintName == "type"
				errors.push new ProviderError styles.ctx(err.instanceContext) + " must be a " + err.constraintValue, provider:provider
			else if err.constraintName == "format"
				errors.push new ProviderError styles.ctx(err.instanceContext) + " is not a valid " + err.constraintValue, provider:provider
			else
				console.error 'unknown error:', err
		errs = new_errs

	if errors_count
		errors.push new ProviderError 'Stoping at check step 2/3', provider:provider
		return

	if not data.href
		errors.push new ProviderWarning "Should have field " + styles.ctx('#/href') + " in provider", provider:provider
	else
		checkHref provider, data.href, errors

	checkOAuth1 provider, data.oauth1, data, errors if data.oauth1
	checkOAuth2 provider, data.oauth2, data, errors if data.oauth2
	checkParameters provider, data.parameters, '#/parameters', errors if data.parameters

	isDefaultParameters = (params) ->
		return params.client_id == 'string' && params.client_secret == 'string' &&
			Object.keys(params).length == 2
	if data.parameters
		if not data.oauth1?.parameters && not data.oauth2?.parameters && isDefaultParameters(data.parameters)
			errors.push new ProviderWarning styles.ctx('#/parameters') + ' can be removed (using default)', provider:provider
	else
		if data.oauth1?.parameters
			if not data.oauth2?.parameters && isDefaultParameters(data.oauth1.parameters)
				errors.push new ProviderWarning styles.ctx('#/oauth1/parameters') + ' can be removed (using default)', provider:provider
		else if data.oauth2?.parameters && isDefaultParameters(data.oauth2.parameters)
			errors.push new ProviderWarning styles.ctx('#/oauth2/parameters') + ' can be removed (using default)', provider:provider

	return

checkAll = (callback) ->
	fs.readdir rootdir + '/providers', (err, providers) ->
		callback new Error 'Could not read providers folder' if err
		errors = []
		tasks = []
		count = 0
		for provider in providers
			do (provider) -> tasks.push (cb) ->
				return cb() if provider is 'default'
				count++
				fs.exists rootdir + '/providers/' + provider + '/logo.png', (exist) ->
					if not exist
						errors.push new ProviderWarning "Missing " + provider + "/logo.png", provider:provider
				if not provider.match /^[a-zA-Z0-9\-_]{2,}$/
					errors.push new ProviderError "Bad provider name", provider:provider
					cb()
				if not provider.match /^[a-z0-9\-_]+$/
					errors.push new ProviderError "Provider's name must be lowercase", provider:provider
					cb()
				if not provider.match /^[a-z0-9_]+$/
					errors.push new ProviderWarning "Provider's name shoud use underscore '_' instead of dash '-'", provider:provider
				fs.readFile rootdir + '/providers/' + provider + '/conf.json', (err, data) ->
					errors.push new ProviderError "Could not read provider", provider:provider if err
					checkProvider provider, data, errors if not err
					cb()

		async.parallel tasks, (err, res) ->
			return callback err if err
			return callback new Error 'Something gone wrong ! no providers checked' if not count
			return callback null, count:count, errors:errors
		return

checkAll (err, infos) ->
	tags =
		fatal: styles.wrap(['bold', 'redBG'], "[FATAL ERROR]") + "\t"
		error: styles.wrap ['bold', 'red'], "[ERROR]" + "\t"
		warning: styles.wrap ['bold', 'yellow'], "[WARNING]" + "\t"
		info: styles.wrap ['bold', 'green'], "[INFO]" + "\t"
		provider: (provider) -> styles.wrap ['bold', 'cyan'], "[" + provider + "]\t"
	if err
		console.error tags.fatal + err.message
		process.exit 1
	providers = {}
	gerrors = []
	retcode = 0
	for v in infos.errors
		if v instanceof ProviderError
			providers[v.provider] ?= errors:[], warnings:[]
			providers[v.provider].errors.push v
		else if v instanceof ProviderWarning
			providers[v.provider] ?= errors:[], warnings:[]
			providers[v.provider].warnings.push v
		else if v instanceof Error
			gerrors.push v
	console.log tags.info + "Checked " + infos.count + " providers"
	for e in gerrors
		console.error tags.error + e.message
	for name in Object.keys(providers).sort()
		provider = providers[name]
		for e in provider.warnings
			console.log tags.provider(name) + tags.warning + e.message
		for e in provider.errors
			console.error tags.provider(name) + tags.error + e.message
			retcode = 1
	process.exit retcode
