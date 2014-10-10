jf = require 'jsonfile'
Q = require 'q'

module.exports = () ->
	defer = Q.defer()
	jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
		return defer.reject err if err
		plugins = []
		if obj?
			plugins = Object.keys(obj)
		defer.resolve(plugins)
	defer.promise