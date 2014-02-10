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

'use strict'

restify = require 'restify'
fs = require 'fs'
Url = require 'url'

{db} = shared = require '../shared'

db_getApps = (callback) ->
	db.redis.smembers 'adm:apps', (err, apps) ->
		return callback err if err
		return callback null, [] if not apps.length
		keys = ('a:' + app + ':key' for app in apps)
		db.redis.mget keys, (err, appkeys) ->
			return callback err if err
			return callback null, appkeys

## Event: add app to user when created
shared.on 'app.create', (req, app) ->
	db.redis.sadd 'adm:apps', app.id

## Event: remove app from user when deleted
shared.on 'app.remove', (req, app) ->
	db.redis.srem 'adm:apps', app.id

exports.setup = (callback) ->

	rmBasePath = (req, res, next) =>
		if req.path().substr(0, @config.base.length) == @config.base
			req._path = req._path.substr(@config.base.length)
		next()

	sendIndex = (req, res, next) =>
		fs.readFile __dirname + '/app/index.html', 'utf8', (err, data) =>
			res.setHeader 'Content-Type', 'text/html'
			data = data.toString().replace /\{\{if admin\}\}([\s\S]*?)\{\{endif\}\}\n?/gm, if req.user then '$1' else ''
			data = data.replace /\{\{jsconfig\}\}/g, "var oauthdconfig={host_url:\"#{@config.host_url}\",base:\"#{@config.base}\",base_api:\"#{@config.base_api}\"};"
			data = data.replace /\{\{baseurl\}\}/g, "#{@config.base}"
			res.end data
			next()

	@server.get @config.base + '/admin', @auth.optional, ((req, res, next) =>
			if db.redis.last_error
				res.setHeader 'Location', @config.host_url + @config.base + "/admin/error#err=" + encodeURIComponent(db.redis.last_error)
				res.send 302
				next false
			next()
		), sendIndex

	@server.get new RegExp('^' + @config.base + '\/(lib|css|js|img|templates)\/.*'), rmBasePath, restify.serveStatic
		directory: __dirname + '/app'
		maxAge: 1

	@server.get new RegExp('^' + @config.base + '\/admin\/(lib|css|js|img|templates)\/*'), rmBasePath, @auth.needed, restify.serveStatic
		directory: __dirname + '/app'
		maxAge: 1

	# get my infos
	@server.get @config.base_api + '/me', @auth.needed, (req, res, next) =>
		db_getApps (e, appkeys) ->
			return next(e) if e
			res.send apps:appkeys
			next()

	@server.get new RegExp('^' + @config.base + '\/admin\/(.*)'), @auth.optional, ((req, res, next) =>
			if req.params[0] == "logout"
				res.setHeader 'Set-Cookie', 'accessToken=; Path=' + @config.base + '/admin; Expires=' + (new Date(0)).toUTCString()
				delete req.user
			if not req.user && req.params[0] != "error"
				res.setHeader 'Location', @config.host_url + @config.base + "/admin"
				res.send 302
				next false
			next()
		), sendIndex

	callback()