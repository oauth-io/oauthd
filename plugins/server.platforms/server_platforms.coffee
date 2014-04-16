# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

'use strict'

restify = require 'restify'
{config,check,db} = shared = require '../shared'

exports.raw = ->

	@on 'platform.remove', (platform) =>
		if platform? and platform.name? and platform.id?
			db.platforms.removeAdminsOfPlatform platform.name, (err) ->
				console.log "Error removing admins of platform " + platform.name + " with id " + platform.id + ".", err
		else
			console.log "Missing informations to remove admins of platform." 