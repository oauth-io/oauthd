fs = require 'fs'
ncp = require 'ncp'
jf = require 'jsonfile'
exec = require('child_process').exec
colors = require 'colors'

Q = require 'q'



module.exports = (name, force) ->
	defer = Q.defer()

	path = process.cwd() + '/plugins/' + name
	exists = fs.existsSync process.cwd() + '/plugins/' + name

	if not exists or force
		ncp __dirname + '/../../templates/plugin', path, (err) ->
			if err
				return defer.reject err
			else
				jf.readFile path + '/plugin.json', (err, obj) ->
					return defer.reject(err) if err
					if not obj?
						obj = {}
					obj.name = name
					jf.writeFile path + 'plugin.json', obj, (err) ->
						return defer.reject err if err
						exec 'cd ' + path + '&& git init', (error, stdout, stderr) ->
							if not error
								console.log 'The plugin ' + name.green + ' was successfully created in ./plugins/' + name
							else
								console.log 'An error occured while initializing the plugin git repo'.red
	else
		console.log 'The plugin ' + name.yellow + ' already exists. To override, use ' + '--force'.green



	defer.promise