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

oauth =
	oauth1: require '../../lib/oauth1'
	oauth2: require '../../lib/oauth2'

exports.setup = (callback) ->

	doRequest = (req, res, next) =>
		cb = @server.send(res, next)
		oauthio = req.headers.oauthio
		if ! oauthio
			return cb new @check.Error "You must provide a valid 'oauthio' http header"
		oauthio = qs.parse(oauthio)
		if ! oauthio.k
			return cb new @check.Error "oauthio_key", "You must provide a 'k' (key) in 'oauthio' header"
		async.parallel [
			(callback) => @db.providers.getExtended req.params[0], callback
			(callback) => @db.apps.getKeyset oauthio.k, req.params[0], callback
		], (err, results) =>
			return cb err if err
			[provider, {parameters}] = results

			# select oauth version
			oauthv = oauthio.oauthv && {
				"2":"oauth2"
				"1":"oauth1"
			}[oauthio.oauthv]
			if oauthv and not provider[oauthv]
				return cb new @check.Error "oauthio_oauthv", "Unsupported oauth version: " + oauthv
			oauthv ?= 'oauth2' if provider.oauth2
			oauthv ?= 'oauth1' if provider.oauth1

			parameters.oauthio = oauthio

			# let oauth modules do the request
			oauth[oauthv].request provider, parameters, req, (err, api_request) ->
				return cb err if err
				res.setHeader('Access-Control-Allow-Origin', 'http://localhost:6284') # todo <- override by request's pipe, make domain list
				res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE') # todo <- override by request's pipe
				api_request.pipe(res)
				api_request.once 'end', -> next false

	# request's endpoints
	@server.get new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.post new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.put new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.patch new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest
	@server.del new RegExp('^' + @config.base + '/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest

	callback();