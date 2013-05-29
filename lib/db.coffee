redis = require 'redis'

config = require '../config'

class WshDb
	constructor: ->
		@redis = null

	init: (callback) ->
		try
			@redis = redis.createClient()
		catch e
			callback e

	close: (callback) ->
		try
			@redis.quit() if @redis
		catch e
			callback e

module.exports = new WshDb