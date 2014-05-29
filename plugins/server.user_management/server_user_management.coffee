# OAuth daemon
# Copyright (C) 2014 Webshell SAS
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
request = require 'request'

oauth =
	oauth1: require '../../lib/oauth1'
	oauth2: require '../../lib/oauth2'

fixUrl = (ref) -> ref.replace /^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2'


sendAbsentFeatureError = (req, res, feature) ->
	res.send 501, "This provider does not support the " + feature + " feature yet"

cors_middleware = (req, res, next) ->
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
	res.setHeader 'Access-Control-Allow-Origin', origin
	res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE'
	next()

exports.raw = ->
	fixUrl = (ref) -> ref.replace /^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2'



	@server.opts new RegExp('^/auth/([a-zA-Z0-9_\\.~-]+)/me$'), (req, res, next) =>
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

	@server.get new RegExp('^/auth/([a-zA-Z0-9_\\.~-]+)/me$'), cors_middleware, (req, res, next) =>
		cb = @server.send res, next
		provider = req.params[0]
		@db.providers.getMeMapping provider, (err, content) =>
			if !err
				if content.url
					oauthio = req.headers.oauthio
					if ! oauthio
						return cb new @check.Error "You must provide a valid 'oauthio' http header"
					oauthio = qs.parse(oauthio)
					if ! oauthio.k
						return cb new @check.Error "oauthio_key", "You must provide a 'k' (key) in 'oauthio' header"
					@apiRequest apiUrl: content.url, provider, oauthio, (err, options) =>
						return sendAbsentFeatureError(req, res, 'me()') if err
						options.json = true
						request options, (err, response, body) =>
							return sendAbsentFeatureError(req, res, 'me()') if err
							res.send body
				else
					return sendAbsentFeatureError(req, res, 'me()')
			else
				return sendAbsentFeatureError(req, res, 'me()')