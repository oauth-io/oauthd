# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

restify = require 'restify'
shared = require '../shared'

exports.needed = (req, res, next) ->
	if not req.params.k
		return next new restify.MissingParameterError "Missing OAuth.io public key."
	if not req.params.secret
		return next new restify.MissingParameterError "Missing OAuth.io secret key."
	req.user = id:1
	return next()

shared.auth = exports