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

restify = require 'restify'

module.exports = (env) ->

	check = env.utilities.check
	config = env.config

	buildReply = (body, res) ->
		body = null if body == check.nullv
		if body instanceof Error
			if config.debug
				body.body ?= {}
				body.body.stack = body.stack.split "\n" if body.stack
			else if not body.statusCode && not (body instanceof check.Error)
				body = new restify.InternalError "Internal error"
			res.statusCode = body.statusCode || 500
			res.statusCodeInternal = body.statusCode?
			res.message = body.message
			res.statusStr = body.status || 'error'

			body = body.body if body.body
			delete body.message if body.code && body.message?
		else
			res.statusStr = 'success'
			if Buffer.isBuffer(body)
				body = body.toString('base64')

		if res.buildJsend || res.buildJsend != false &&
			not (res.statusStr == 'error' && body?.error && body?.error_description) &&
			not (res.statusStr == 'success' && body?.access_token && body?.token_type)
				result = status: res.statusStr
				if res.statusStr == 'error'
					result.code = res.statusCode if res.statusCodeInternal
					result.message = res.message
					result.data = body if typeof body == 'object' && Object.keys(body).length
				else
					if res.statusCode < 200 or res.statusCode >= 300
						result.status = 'error'
					body = null if not body?
					result.data = body
				body = result
		return body

	formatters =
		'application/json; q=0.9': (req, res, body, cb) ->
			data = JSON.stringify buildReply(body, res)
			res.setHeader 'Content-Type', "application/json; charset=utf-8"
			res.setHeader 'Content-Length', Buffer.byteLength(data)
			return cb null, data

		'application/javascript; q=0.1': (req, res, body, cb) ->
			return cb null, "" if body instanceof Error && not config.debug
			body = body.toString()
			res.setHeader 'Content-Type', "application/javascript; charset=utf-8"
			res.setHeader 'Content-Length', Buffer.byteLength(body)
			return cb null, body

		'text/html; q=0.1': (req, res, body, cb) ->
			if body instanceof Error
				if body instanceof check.Error || body instanceof restify.RestError
					msg = check.escapeHtml body.message
					if typeof body.body == 'object' && Object.keys(body.body).length
						msg += "<br/>"
						for k,v of body.body
							msg += '<span style="color:red">' + (check.escapeHtml k.toString()) + "</span>: " + (check.escapeHtml v.toString()) + "<br/>"
					else if typeof body.body == 'string' && body.body != ""
						msg += '<br/><span style="color:red">' + (check.escapeHtml body.body) + '</span>'
					if config.debug && body.stack
						stack = if body.we_cause?.stack then body.we_cause.stack else body.stack
						msg += "<br/>" + (check.escapeHtml stack).replace(/\n/g, '<br/>')
					body = msg
				else
					body = "Internal error"
			body = body.toString()
			res.setHeader 'Content-Type', "text/html; charset=utf-8"
			res.setHeader 'Content-Length', Buffer.byteLength(body)
			return cb null, body

	{
		formatters: formatters
		build: (e,r) -> buildReply e || r, buildJsend: true
	}

