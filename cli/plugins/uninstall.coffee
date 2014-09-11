fs = require 'fs'
rimraf = require 'rimraf'
jf = require 'jsonfile'

module.exports = (cli) ->
	cli.argv._.shift()
	plugin_name = ""
	for elt in cli.argv._
		if plugin_name != ""
			plugin_name += " "
		plugin_name += elt

	if plugin_name == ""
		return console.log 'Please provide a plugin name to uninstall.'

	try
		folder_name = process.cwd() + "/plugins/" + plugin_name
		fs.exists folder_name, (exists) ->
			if exists
				rimraf folder_name, (err) ->
					throw err if err
					console.log "Successfully removed plugin '" + plugin_name + "' folder."
			jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
				throw err if err
				if obj? and obj[plugin_name]?
					delete obj[plugin_name]
					jf.writeFile process.cwd() + '/plugins.json', obj, (err) ->
						throw err if err
						console.log "Successfully removed plugin '" + plugin_name + "' from the plugins list."
	catch e
			console.log 'An error occured: ' + e.message