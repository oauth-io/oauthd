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

db = require './db'
querystring = require 'querystring'
config = require './config'

class OAuthBase
	constructor: (oauthv, provider, parameters) ->
		@_params = {}
		@_oauthv = oauthv
		@_provider = provider
		@_oauthConfiguration = provider[oauthv];
		@_parameters = parameters
		@_serverCallbackUrl = config.host_url + config.relbase
		@_setParams @_provider.parameters
		@_setParams @_provider[oauthv].parameters

	_setParams: (parameters) ->
		@_params[k] = v for k,v of parameters
		return

	_replaceParam: (param, hard_params) ->
		param = param.replace /\{\{(.*?)\}\}/g, (match, val) ->
			return db.generateUid() if val == "nonce"
			return hard_params[val] || ""
		param = param.replace /\{(.*?)\}/g, (match, val) =>
			return "" if ! @_params[val] || ! @_parameters[val]
			if Array.isArray(@_parameters[val])
				return @_parameters[val].join(@_params[val].separator || ",")
			return @_parameters[val]
		return param.replace /!BASE64(.*?)!BASE64/g, (match, val) ->
			return (new Buffer val).toString('base64')

	_createState: (opts, callback) ->
		newStateData =
			key: opts.key,
			provider: @_provider.provider,
			redirect_uri: opts.redirect_uri,
			oauthv: @_oauthv,
			origin: opts.origin,
			options: opts.options,
			expire: 1200
		db.states.add newStateData, callback

	_buildQuery : (configuration, placeholderValues, defaultParameters) ->
		query = if (defaultParameters instanceof Object) then defaultParameters else {}
		# replaces '{{placeholder1}}' in placeholders[parameterName]
		# with matching placeholderValues's 'placeholder1' value
		for parameterName, placeholder of configuration
			param = @_replaceParam(placeholder, placeholderValues)
			query[parameterName] = param if param
		return query

	_buildAuthorizeUrl: (url, query, stateId) ->
		url = @_replaceParam(url, {})
		url += "?" + querystring.stringify(query)
		return { url: url, state: stateId }

	_buildServerRequestOptions: (req) ->
		return {
			method: req.method
			followAllRedirects: true
			url: @_buildServerRequestUrl(req.apiUrl, req, @_oauthConfiguration.request.url)
			qs: @_buildServerRequestQuery(@_oauthConfiguration.request.query)
			headers: @_buildServerRequestHeaders(req.headers, @_oauthConfiguration.request.headers)
		}

	_buildServerRequestUrl: (url, req, configurationUrl) ->
		if typeof req.query == 'function' and typeof req.query() == 'string'
			url += "?" + req.query()
		if ! url.match(/^[a-z]{2,16}:\/\//)
			if url[0] != '/'
				url = '/' + url
			url = configurationUrl + url
		return @_replaceParam(url, @_parameters.oauthio)

	_buildServerRequestQuery: (configurationQuery) ->
		return @_buildQuery(configurationQuery, @_parameters.oauthio)

	_buildServerRequestHeaders: (reqHeaders, configurationHeaders) ->
		ignoreheaders = [
			'oauthio', 'host', 'connection',
			'origin', 'referer'
		]

		headers = {}
		for k, v of reqHeaders
			if ignoreheaders.indexOf(k) == -1
				k = k.replace /\b[a-z]/g, (-> arguments[0].toUpperCase())
				headers[k] = v

		for parameterName, placeholder of configurationHeaders
			param = @_replaceParam(placeholder, @_parameters.oauthio)
			headers[parameterName] = param if param
		return headers

	_getExpireParameter: (response) ->
		expire = response.body.expire
		expire ?= response.body.expires
		expire ?= response.body.expires_in
		expire ?= response.body.expires_at
		if expire
			expire = parseInt expire
			now = (new Date).getTime()
			expire -= now if expire > now
		return expire

	_cloneRequest: () ->
		clonedRequest = {}
		clonedRequest[k] = v for k, v of @_oauthConfiguration.request
		for k, v of @_params
			if v.scope == 'public'
				clonedRequest.parameters ?= {}
				clonedRequest.parameters[k] = @_parameters[k]
		return clonedRequest

	_setExtraResponseParameters: (configuration, response, data) ->
		for extra in (configuration.extra || [])
			data[extra] = response.body[extra] if response.body[extra]

	_setExtraRequestAuthorizeParameters: (request, data) ->
		for extra in (@_oauthConfiguration.authorize.extra || [])
			data[extra] = request.params[extra] if request.params[extra]

	_buildHeaders: (configuration, headerParameters = {}) ->
		shortFormats = { json: 'application/json', url: 'application/x-www-form-urlencoded' }
		headers = {}
		headers["Accept"] = shortFormats[configuration.format] || configuration.format if configuration.format
		for name, value of configuration.headers
			param = @_replaceParam(value, headerParameters)
			headers[name] = param if param
		return headers

	_buildRequestOptions: (configuration, headers, query) ->
		method = configuration.method?.toUpperCase() || 'POST'
		options = {
			url: @_replaceParam(configuration.url, {})
			method: method
			encoding: null
			form: query if method != 'GET'
			qs: query if method == 'GET'
			headers: headers if Object.keys(headers).length
		}
		return options

module.exports = OAuthBase