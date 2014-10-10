Q = require 'q'
exec = require('child_process').exec

module.exports = (env) ->
	() ->
		defer = Q.defer()
		env.debug 'Running npm install and grunt.'.green + ' This may take a few minutes'.yellow
		exec 'npm install; grunt;', (error, stdout, stderr) ->
			if not error
				defer.resolve()
			else
				defer.reject()
		defer.promise