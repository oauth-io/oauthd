# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

restify = require 'restify'
check = require './check'
config = require './config'

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

	if res.buildJsend ||
		not (res.statusStr == 'error' && body?.error && body?.error_description) &&
		not (res.statusStr == 'success' && body?.access_token && body?.token_type)
			result = status: res.statusStr
			if res.statusStr == 'error'
				result.code = res.statusCode if res.statusCodeInternal
				result.message = res.message
				result.data = body if body? && Object.keys(body).length
			else
				body = null if not body?
				result.data = body
			body = result
	return body

formatters =
	'application/json': (req, res, body) ->
		data = JSON.stringify buildReply(body, res)
		res.setHeader 'Content-Type', "application/json; charset=utf-8"
		res.setHeader 'Content-Length', Buffer.byteLength(data)
		return data

	'application/javascript': (req, res, body) ->
		return "" if body instanceof Error && not config.debug
		body = body.toString()
		res.setHeader 'Content-Type', "application/javascript; charset=utf-8"
		res.setHeader 'Content-Length', Buffer.byteLength(body)
		return body

	'text/html': (req, res, body) ->
		return "" if body instanceof Error && not config.debug
		body = body.toString()
		res.setHeader 'Content-Type', "text/html; charset=utf-8"
		res.setHeader 'Content-Length', Buffer.byteLength(body)
		return body

module.exports =
	formatters: formatters
	build: (e,r) -> buildReply e || r, buildJsend: true