Q = require 'q'
async = require 'async'


module.exports = (env) ->

	class Entity
		@entity_prefix: ''
		@incr_key: ''
		@load: (id) ->
			return
		id: 0
		data: {}
		prefix: ''
		constructor: (id) ->
			@prefix = Entity.entity_prefix + ':' + id + ':'
		keys: () ->
			defer = Q.defer()
			keys = {}
			env.data.redis.keys @prefix + '*', (e, result) ->
				if e
					defer.reject e
				else
					defer.resolve e

			defer.promise
		typedKeys: () ->
			defer = Q.defer()
			keys = {}
			env.data.redis.keys @prefix + '*', (e, result) ->
				async.eachSeries result
				, (key, next) ->
					env.data.redis.type key, (e, type) ->
						defer.reject(e) if e
						keys[key] = type
						next()
				, (e, final_result) ->
					if e
						defer.reject(e)
					else
						defer.resolve(keys)

			defer.promise

		getAll: () ->
			defer = Q.defer()

			@typedKeys()
				.then (keys) ->
					cmds = []

					for key, type of keys
						if type == 'hash'
							cmds.push ['hgetall', @prefix + key]
						if type == 'string'
							cmds.push ['get', @prefix + key]

					env.data.redis.multi cmds, (err, fields) ->
						profile = {}
						for k,v of fields
							profile[keys[k]] = v

						defer.resolve(profile)
				.fail (e) ->
					defer.reject e

			defer.promise
		get: (key) ->
			defer = Q.defer()

			env.data.redis.get @prefix + key, (e, value) ->
				if e
					defer.reject e
				else
					defer.resolve value

			defer.promise
		set: (key, value) ->
			defer = Q.defer()

			env.data.redis.set @prefix + key, value, (e) ->
				if e
					defer.reject e
				else
					defer.resolve()

			defer.promise
		hget: (hkey, key) ->
			defer = Q.defer()

			env.data.redis.hget @prefix + hkey, key, (e, value) ->
				if e
					defer.reject e
				else
					defer.resolve value

			defer.promise
		hset: (hkey, key, value) ->
			defer = Q.defer()

			env.data.redis.hset @prefix + hkey, key, value, (e) ->
				if e
					defer.reject e
				else
					defer.resolve()

			defer.promise



	Entity	