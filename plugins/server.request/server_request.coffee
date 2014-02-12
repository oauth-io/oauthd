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

async = require 'async'
qs = require 'querystring'
Url = require 'url'
restify = require 'restify'

oauth =
	oauth1: require '../../lib/oauth1'
	oauth2: require '../../lib/oauth2'

exports.setup = (callback) ->

	fixUrl = (ref) -> ref.replace /^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2'

	doRequest = (req, res, next) =>
		cb = @server.send(res, next)
		oauthio = req.headers.oauthio
		if ! oauthio
			return cb new @check.Error "You must provide a valid 'oauthio' http header"
		oauthio = qs.parse(oauthio)
		if ! oauthio.k
			return cb new @check.Error "oauthio_key", "You must provide a 'k' (key) in 'oauthio' header"

		origin = null
		ref = fixUrl(req.headers['referer'] || req.headers['origin'] || "http://localhost");
		urlinfos = Url.parse(ref)
		if not urlinfos.hostname
			ref = origin = "http://localhost"
		else
			origin = urlinfos.protocol + '//' + urlinfos.host

		async.parallel [
			(callback) => @db.providers.getExtended req.params[0], callback
			(callback) => @db.apps.getKeyset oauthio.k, req.params[0], callback
			(callback) => @db.apps.checkDomain oauthio.k, ref, callback
		], (err, results) =>
			return cb err if err
			[provider, {parameters}, domaincheck] = results

			if ! domaincheck
				return cb new @check.Error 'Origin "' + ref + '" does not match any registered domain/url on ' + @config.url.host

			# select oauth version
			oauthv = oauthio.oauthv && {
				"2":"oauth2"
				"1":"oauth1"
			}[oauthio.oauthv]
			if oauthv and not provider[oauthv]
				return cb new @check.Error "oauthio_oauthv", "Unsupported oauth version: " + oauthv
			oauthv ?= 'oauth2' if provider.oauth2
			oauthv ?= 'oauth1' if provider.oauth1
			oa = new oauth[oauthv]

			parameters.oauthio = oauthio

			# let oauth modules do the request
			oa.request provider, parameters, req, (err, api_request) ->
				return cb err if err

				api_request.pipefilter = (response, dest) ->
					dest.setHeader 'Access-Control-Allow-Origin', origin
					dest.setHeader 'Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE'
				api_request.pipe(res)
				api_request.once 'end', -> next false

	@server.opts new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), (req, res, next) ->
		origin = null
		ref = fixUrl(req.headers['referer'] || req.headers['origin'] || "http://localhost");
		urlinfos = Url.parse(ref)
		if not urlinfos.hostname
			return next new restify.InvalidHeaderError 'Missing origin or referer.'
		origin = urlinfos.protocol + '//' + urlinfos.host

		res.setHeader 'Access-Control-Allow-Origin', origin
		res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE'
		if req.headers['access-control-request-headers']
			res.setHeader 'Access-Control-Allow-Headers', req.headers['access-control-request-headers']
		res.cache maxAge: 120

		res.send 200
		next false

	# request's endpoints
	@server.get new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.post new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.put new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.patch new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.del new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest

	callback();