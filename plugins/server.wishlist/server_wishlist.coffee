# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

exports.setup = (callback) ->

	@db.wishlist = require './db_wishlist'

	# add provider to wishlist
	@server.post @config.base_api + '/wishlist/add', @auth.needed, (req, res, next) =>
		@db.wishlist.add req.body.name, req.clientId.id, @server.send(res, next)

	# get wishlist
	@server.get @config.base_api + '/wishlist', (req, res, next) =>
		@db.wishlist.getList full:false, @server.send(res, next)



	callback()