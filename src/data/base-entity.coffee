Q = require 'q'
async = require 'async'


module.exports = (env) ->

	class Entity
		@prefix: ''
		@incr: ''
		@findById: (id) ->
			defer = Q.defer()
			lapin = new @(id)
			lapin.load()
				.then () ->
					defer.resolve lapin
				.fail (e) ->
					defer.reject e
			defer.promise
		@onCreate: (entity) ->
			# creation additional operations
		@onUpdate: (entity) ->
			# update additional operations
		@onSave: (entity) ->
			# save additional operations (always called)
		@onRemove: (entity) ->
			# removal additional operations
		@onCreateAsync: (entity, done) ->
			# async creation additional operations
			done()
		@onUpdateAsync: (entity, done) ->
			# async update additional operations
			done()
		@onSaveAsync: (entity, done) ->
			# async save additional operations (always called)
			done()
		@onRemoveAsync: (entity, done) ->
			# asunc removal additional operations
			done()
		id: 0 # represents the entity in db
		props: {} # the entity's properties
		prefix: () -> # the prefix of the entity, e.g. user:23:
			@constructor.prefix + ':' + @id + ':'
		constructor: (id) ->
			@id = id 
		keys: () ->
			defer = Q.defer()
			keys = {}
			env.data.redis.keys @prefix() + '*', (e, result) ->
				if e
					defer.reject e
				else
					defer.resolve result

			defer.promise
		typedKeys: () ->
			defer = Q.defer()
			keys = {}
			env.data.redis.keys @prefix() + '*', (e, result) =>
				async.eachSeries result
				, (key, next) =>
					env.data.redis.type key, (e, type) =>
						defer.reject(e) if e
						keyname = key.replace @prefix(), ''
						keys[keyname] = type
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
				.then (keys) =>
					cmds = []

					for key, type of keys
						if type == 'hash'
							cmds.push ['hgetall', @prefix() + key]
						if type == 'string'
							cmds.push ['get', @prefix() + key]
						if type == 'set'
							cmds.push ['smembers', @prefix() + key]

					env.data.redis.multi(cmds).exec (err, fields) ->
						object = {}
						keys_array = Object.keys keys
						for k, v of fields
							object[keys_array[k]] = v
						defer.resolve(object)
				.fail (e) ->
					defer.reject e

			defer.promise
		load: () ->
			defer = Q.defer()
			@getAll()
				.then (data) =>
					@props = data
					defer.resolve(data)
				.fail (e) ->
					defer.reject(e)

			defer.promise

		save: () ->
			defer = Q.defer()
			
			# hat function that actually saves
			_save = (done) =>
				multi = env.data.redis.multi()

				@keys()
					.then (keys) =>
						prefixedProps = []
						for key in Object.keys(@props)
							prefixedProps.push @prefix() + key
						for key in keys
							if key not in prefixedProps
								multi.del key
						for key, value of @props
							if typeof value == 'string' or typeof value == 'number'
								multi.set @prefix() + key, value
							else if typeof value == 'object' and Array.isArray(value)
								multi.del @prefix() + key
								for k, v of value
									multi.sadd @prefix() + key, v
							else if	value? and typeof value == 'object'
								multi.del @prefix() + key
								multi.hmset @prefix() + key, value
							else
								# TODO (value instanceof Boolean || typeof value == 'boolean')
								console.log "not saved: type not found"

						# actual save
						multi.exec (e, res) =>
							return done e if e
							done()
					.fail (e) =>
						return done e if e

			# checks if new entity or not. If no id found, increments ids
			if not @id?
				env.data.redis.incr @constructor.incr, (e, id) =>
					@id = id
					_save (e) =>
						return defer.reject e if e
						@constructor.onCreate @
						@constructor.onSave @
						@constructor.onCreateAsync @, (e) =>
							return defer.reject e if e
							@constructor.onSaveAsync @, (e) =>
								return defer.reject e if e
								defer.resolve()
			else
				_save (e) =>
					return defer.reject e if e
					@constructor.onUpdate @
					@constructor.onSave @
					@constructor.onUpdateAsync @, (e) =>
						return defer.reject e if e
						@constructor.onSaveAsync @, (e) =>
							return defer.reject e if e
							defer.resolve()

			
			defer.promise
		remove: () ->
			defer = Q.defer()
			multi = env.data.redis.multi()
			@keys()
				.then (keys) =>
					for key in keys
						multi.del key
					multi.exec (e) =>
						return defer.reject e if e
						@constructor.onRemoveAsync @, (e) ->
							return defer.reject e if e
							defer.resolve()
				.fail (e) =>
					defer.reject e
			defer.promise

	Entity