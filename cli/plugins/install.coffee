exec = require('child_process').exec
fs = require 'fs'
ncp = require 'ncp'
rimraf = require 'rimraf'
jf = require 'jsonfile'
# shared = require '../../../bin/plugin_shared'
# config = require '../../../bin/config'
# {check,db} = shared

module.exports = (cli) ->
	cli.argv._.shift()

	plugin_repo = cli.argv._[0]

	if not plugin_repo?
		return console.log 'Please provide a repository address for the plugin to install'
	temp_location = process.cwd() + '/plugins/cloned'
	try
		rimraf temp_location, (err) ->
			throw err if err
			exec 'cd ' + temp_location + '; git clone ' + plugin_repo + ' ' + temp_location, (error, stdout, stderr) ->
				plugin_data = require(temp_location + '/plugin.json')
				folder_name = process.cwd() + "/plugins/" + plugin_data.name
				rimraf folder_name, (err) ->
					throw err if err
					fs.rename process.cwd() + '/plugins/cloned', process.cwd() + '/plugins/' + plugin_data.name, (err) ->
						throw err if err
						console.log 'Plugin "' + plugin_data.name + '" successfully installed in "'+ folder_name + '".'
						file =  process.cwd() + '/plugins.json'
						jf.spaces = 4
						jf.readFile file, (err, obj) ->
							throw err if err
							if not obj?
								obj = {}
							obj[plugin_data.name] = plugin_data.version
							jf.writeFile file, obj, (err) ->
								throw err if err
								console.log 'Plugin "' + plugin_data.name + '" successfully added to the plugins list.'
						# fs.readFile process.cwd() + '/config.js', (err, data) ->
						# 	console.log "config js data", data
						# 	console.log "config js data.toString()", data.toString()
	catch e
		console.log 'An error occured: ' + e.message	




