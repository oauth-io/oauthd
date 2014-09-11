exec = require('child_process').exec
fs = require 'fs'
ncp = require 'ncp'
rimraf = require 'rimraf'

module.exports = (cli) ->
	cli.argv._.shift()

	plugin_repo = cli.argv._[0]

	if not plugin_repo?
		return console.log 'Please provide a repository address for the plugin to install'

	temp_location = process.cwd() + '/plugins/cloned'
	exec 'cd ' + temp_location + '; git clone ' + plugin_repo +  ' ' + temp_location, (error, stdout, stderr) ->
		try
			plugin_data = require(temp_location + '/plugin.json')
			console.log plugin_data.name
			rimraf
			fs.rename process.cwd() + '/plugins/cloned', process.cwd() + '/plugins/' + plugin_data.name, (err) ->
				throw err if err
				console.log 'Plugins "' + plugin_data.name + '" installed.'
		catch e
			console.log 'An error occured: ' + e.message