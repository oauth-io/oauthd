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
	if typeof data.request == 'object'
		a = data.request
		if a.url && Object.keys(a).length == 1
			rooturl = Url.parse(root.url || '')
			aurl = Url.parse(a.url)
			if rooturl.protocol == aurl.protocol && rooturl.host == aurl.host && rooturl.port == rooturl.port
				errors.push new ProviderWarning styles.ctx('#/oauth1/request') + ' can be removed (using default)', provider:provider
			else
				errors.push new ProviderWarning styles.ctx('#/oauth1/request') + ' can be compacted as request.url', provider:provider

checkOAuth2 = (provider, data, root, errors) ->
	checkParameters provider, data.parameters, '#/oauth2/parameters', errors if data.parameters

	# oauth2.authorize checks
	if typeof data.authorize == 'object'
		a = data.authorize
		if a.query && a.query.client_id == "{client_id}" && a.query.response_type == "code" &&
			a.query.redirect_uri == "{{callback}}" && a.query.scope == "{scope}" &&
			a.query.state == "{{state}}" && Object.keys(a.query).length == 5
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
	if typeof data.request == 'object'
		a = data.request
		if a.headers && a.headers.Authorization == "Bearer {{token}}" && Object.keys(a.headers).length == 1 &&
			not (a.query && Object.keys(a.query).length)
				errors.push new ProviderWarning styles.ctx('#/oauth2/request/headers') + ' can be removed (using default)', provider:provider
				delete a.headers
		if a.url && Object.keys(a).length == 1
			rooturl = Url.parse(root.url || '')
			aurl = Url.parse(a.url)
			if rooturl.protocol == aurl.protocol && rooturl.host == aurl.host && rooturl.port == rooturl.port
				errors.push new ProviderWarning styles.ctx('#/oauth2/request') + ' can be removed (using default)', provider:provider
			else
				errors.push new ProviderWarning styles.ctx('#/oauth2/request') + ' can be compacted as request.url', provider:provider

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
	errors.push new ProviderWarning styles.ctx('#/href/keys') + ' should be present', provider:provider if not data.keys
	errors.push new ProviderWarning styles.ctx('#/href/apps') + ' should be present', provider:provider if not data.apps
	errors.push new ProviderWarning styles.ctx('#/href/docs') + ' should be present', provider:provider if not data.docs

checkProvider = (provider, data, errors) ->
	# json parsing
	data = JSON.parse data
	# return if provider != "yammer"
	errs = jay.validate(data, "https://oauth.io/provider-schema#")

	while errs.length
		new_errs = []
		for err in errs
			if err.constraintName == "oneOf" && err.kind == "SubSchemaValidationError" && Object.keys(err.subSchemaValidationErrors).length == 1
				err = err.subSchemaValidationErrors[Object.keys(err.subSchemaValidationErrors)[0]]
				new_errs.push e for e in err
			else if err.constraintName == "additionalProperties"
				errors.push new ProviderWarning "Unknown field " + styles.ctx(err.instanceContext + '/' + err.testedValue), provider:provider
			else if err.constraintName == "enum"
				errors.push new ProviderError styles.ctx(err.instanceContext) + " must be " + styles.enum(err.constraintValue), provider:provider
			else if err.constraintName == "required"
				errors.push new ProviderError "Missing field " + styles.ctx(err.instanceContext + '/' + err.desc.substr(9)), provider:provider
			else if err.constraintName == "type"
				errors.push new ProviderError styles.ctx(err.instanceContext) + " must be a " + err.constraintValue, provider:provider
			else
				console.log 'unknown error:', err
		errs = new_errs

	if not data.href
		errors.push new ProviderWarning "Should have field " + styles.ctx('#/href') + " in provider", provider:provider
	else
		checkHref provider, data.href, errors

	checkOAuth1 provider, data.oauth1, data, errors if data.oauth1
	checkOAuth2 provider, data.oauth2, data, errors if data.oauth2
	checkParameters provider, data.parameters, '#/parameters', errors if data.parameters

	return

checkAll = (callback) ->
	fs.readdir rootdir + '/providers', (err, files) ->
		callback new Error 'Could not read providers folder' if err
		errors = []
		tasks = []
		count = 0
		for file in files
			do (file) -> tasks.push (cb) ->
				provider = /(.+)\.json$/.exec file
				return cb() if not provider?[1]
				count++
				provider = provider[1]
				fs.exists rootdir + '/providers/' + provider + '.png', (exist) ->
					if not exist
						errors.push new ProviderWarning "Missing logo file '" + provider + ".png'", provider:provider
				if not provider.match /^[a-zA-Z0-9\-_]{2,}$/
					return errors.push new ProviderError "Bad provider name", provider:provider
				if not provider.match /^[a-z0-9\-_]+$/
					return errors.push new ProviderError "Provider's name must be lowercase", provider:provider
				if not provider.match /^[a-z0-9_]+$/
					errors.push new ProviderWarning "Provider's name shoud use underscore '_' instead of dash '-'", provider:provider
				fs.readFile rootdir + '/providers/' + file, (err, data) ->
					errors.push new ProviderError "Could not read provider", provider:provider if err
					checkProvider provider, data, errors if not err
					cb()

		async.parallel tasks, (err, res) ->
			return callback err if err
			return callback new Error 'Something gone wrong ! no providers checked' if not count
			return callback null, count:count, errors:errors
		return

checkAll (err, infos) ->
	console.log 'finish'
	tags =
		fatal: styles.wrap(['bold', 'redBG'], "[FATAL ERROR]") + "\t"
		error: styles.wrap ['bold', 'red'], "[ERROR]" + "\t"
		warning: styles.wrap ['bold', 'yellow'], "[WARNING]" + "\t"
		info: styles.wrap ['bold', 'green'], "[INFO]" + "\t"
		provider: (provider) -> styles.wrap ['bold', 'cyan'], "[" + provider + "]\t"
	return console.log tags.fatal + err.message if err
	providers = {}
	gerrors = []
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
