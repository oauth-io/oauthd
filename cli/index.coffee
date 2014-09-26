exec = require('child_process').exec
easy_cli = require 'easy-cli'
fs = require 'fs'
ncp = require 'ncp'
prompt = require 'prompt'
installPlugin = require('./plugins/install')
cli = easy_cli()
colors = require 'colors'

# copies an instance basic folder in a new folder at current cwd
if cli.argv._[0] == 'init'
	schema = {
		properties:
			name: {
				pattern: /^[a-zA-Z0-9_\-]+$/
				message: 'You must give a folder name using only letters, digits, dash and underscores'
				description: 'What will be the name of your oauthd instance?'
				require: true
				delimiter: ''
			}
	}
	prompt.message = "oauthd".white
	prompt.delimiter = "> "
	prompt.start()
	prompt.get schema, (err, results) ->
		if not err
			if results.name.length == 0
				console.log 'You must give a folder name using only letters, digits, dash and underscores'
				return
			console.log 'Generating a folder for ' + results.name
			fs.stat './' + results.name, (err, stats) ->
				if not stats
					fs.mkdirSync './' + results.name
				ncp __dirname + '/../templates/basis_structure', process.cwd() + '/' + results.name, (err) ->
					return console.log err if err
					
					schema = {
						properties:
							install_default_plugin: {
								pattern: /^(yes|no)$/
								message: "Please answer by 'yes' or 'no'."
								description: 'Do you want to install default plugins? (recommanded)'
								require: true
							}
					}
					prompt.message = "oauthd".white
					prompt.delimiter = "> "
					prompt.start()
					prompt.get schema, (err, res2) ->
						if not err
							if res2.install_default_plugin is "yes"
								installPlugin("git@github.com:william26/oauthd_default_plugin_auth.git", process.cwd() + "/" + results.name)
								.then () ->
									installPlugin("git@github.com:william26/oauthd_default_plugin_me.git", process.cwd() + "/" + results.name)
								.then () ->
									installPlugin("git@github.com:william26/oauthd_default_plugin_request.git", process.cwd() + "/" + results.name)
								.then () ->
									installPlugin("git@github.com:william26/oauthd_default_plugin_front.git", process.cwd() + "/" + results.name)
								.then () ->
									console.log 'Running npm install & grunt.'.green + ' Please wait, this might take up to a few minutes'.yellow
									exec = require('child_process').exec
									exec 'cd '+ results.name + '; npm install; grunt', (error, stdout, stderr) ->
										console.log 'Done'
										console.log 'Thank you for using oauthd. Run ' + 'oauthd start'.green + ' to start the instance'
								.fail (e) ->
									console.log 'An error occured: '.red + e.message.yellow






# starts oauthd
if cli.argv._[0] == 'start'
	require('../../index').init()


# plugin management
if cli.argv._[0] == 'plugins'
	require('./plugins')(cli)
	