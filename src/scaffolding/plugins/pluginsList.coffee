jf = require 'jsonfile'
Q = require 'q'
fs = require 'fs'
sugar = require 'sugar'
async = require 'async'

module.exports = (scaffolding) ->

	writeEntry = (key, value) ->
		defer = Q.defer()
		jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
			return defer.reject err if err
			if obj?
				obj[key] ?= {}
				for k, v of value
					obj[key][k] = v
				jf.writeFile process.cwd() + '/plugins.json', obj, {spaces: 2}, (err) ->
					return defer.reject err if err
					defer.resolve()
		defer.promise

	modify_module =
		updateEntry: (name, data) ->
			defer = Q.defer()

			writeEntry name, data
				.then () ->
					defer.resolve()
				.fail (e) ->
					defer.reject e


			defer.promise

		removeEntry: (name) ->
			defer = Q.defer()
			jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
				return defer.reject err if err

				if obj?
					delete obj[name]
					jf.writeFile process.cwd() + '/plugins.json', obj, (err) ->
						return defer.reject err if err
						defer.resolve()
			defer.promise


	modify_module