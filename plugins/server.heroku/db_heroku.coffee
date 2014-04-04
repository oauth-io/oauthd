# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

async = require 'async'
request = require 'request'

{config,check,db} = shared = require '../shared'

# Use this call to get a list of apps that have installed your add-on.
# Request       : GET https://username:password@api.heroku.com/vendor/apps
exports.getAllApps = (callback) ->
	options =
		uri: "https://" + config.heroku.heroku_user + ":" + config.heroku.heroku_password + "@api.heroku.com/vendor/apps",
		method: 'GET'

	request options, (err, response, body) ->
		return callback err if err
		return callback null, body