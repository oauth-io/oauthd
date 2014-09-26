exec = require('child_process').exec
fs = require 'fs'
ncp = require 'ncp'
rimraf = require 'rimraf'
jf = require 'jsonfile'

module.exports = (plugin_repo, cwd) ->
	if not plugin_repo?
		return console.log 'Please provide a repository address for the plugin to install'
	temp_location = cwd + '/plugins/cloned'
	try
		rimraf temp_location, (err) ->
			throw err if err
			console.log "Trying to 'git clone' '" + plugin_repo + "'..."
			try
				exec 'cd ' + temp_location + '; git clone ' + plugin_repo + ' ' + temp_location, (error, stdout, stderr) ->
					throw error if error
					console.log "Trying to load 'plugin.json' in the plugin folder..."
					try
						plugin_data = require(temp_location + '/plugin.json')
						folder_name = cwd + "/plugins/" + plugin_data.name
						rimraf folder_name, (err) ->
							throw err if err
							try
								fs.rename cwd + '/plugins/cloned', cwd + '/plugins/' + plugin_data.name, (err) ->
									throw err if err
									console.log 'Plugin "' + plugin_data.name + '" successfully installed in "'+ folder_name + '".'
									file =  cwd + '/plugins.json'
									jf.spaces = 4
									try
										jf.readFile file, (err, obj) ->
											throw err if err
											if not obj?
												obj = {}
											obj[plugin_data.name] = plugin_data.version
											try
												jf.writeFile file, obj, (err) ->
													throw err if err
													console.log 'Plugin "' + plugin_data.name + '" successfully added to the plugins list.'
													# callback null
													# fs.readFile cwd + '/config.js', (err, data) ->
													# 	console.log "config js data", data
													# 	console.log "config js data.toString()", data.toString()
											catch e
												console.log 'An error occured: ' + e.message
									catch e
										console.log 'An error occured: ' + e.message
							catch e
								console.log 'An error occured: ' + e.message
					catch e
						console.log 'An error occured: ' + e.message	
			catch e
				console.log 'An error occured: ' + e.message	
	catch e
		console.log 'An error occured: ' + e.message	
