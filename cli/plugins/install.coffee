exec = require('child_process').exec
fs = require 'fs'
ncp = require 'ncp'
rimraf = require 'rimraf'
jf = require 'jsonfile'
Q = require 'q'
colors = require 'colors'

module.exports = (plugin_repo, cwd) ->
	defer = Q.defer()
	if not plugin_repo?
		return console.log 'Please provide a repository address for the plugin to install'
	temp_location = cwd + '/plugins/cloned'

	rimraf temp_location, (err) ->
		return defer.reject(err) if err
		fs.mkdirSync temp_location
		console.log "Cloning " + plugin_repo.red
		exec 'cd ' + temp_location + '; git clone ' + plugin_repo + ' ' + temp_location, (error, stdout, stderr) ->
			# throw error if error
			return defer.reject error if error
			console.log "Loading plugin information"
			try
				plugin_data = JSON.parse(fs.readFileSync temp_location + '/plugin.json', { encoding: 'UTF-8' })
			catch e 
				return defer.reject e
			folder_name = cwd + "/plugins/" + plugin_data.name
			rimraf folder_name, (err) ->
				return defer.reject(err) if err
				fs.rename cwd + '/plugins/cloned', cwd + '/plugins/' + plugin_data.name, (err) ->
					return defer.reject(err) if err
					console.log 'Plugin "' + plugin_data.name + '" successfully installed in "'+ folder_name + '".'
					
					file =  cwd + '/plugins.json'
					jf.spaces = 4
					jf.readFile file, (err, obj) ->
						return defer.reject(err) if err
						if not obj?
							obj = {}
						if (not obj[plugin_data.name]?) # only add entry to plugins.json if not already there
							obj[plugin_data.name] = plugin_repo
							jf.writeFile file, obj, (err) ->
								return defer.reject(err) if err
								console.log 'Plugin "' + plugin_data.name + '" successfully added to the plugins list.'
								defer.resolve()
						else
							defer.resolve()

	defer.promise
