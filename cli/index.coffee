exec = require('child_process').exec
easy_cli = require 'easy-cli'
fs = require 'fs'
ncp = require 'ncp'
prompt = require 'prompt'

cli = easy_cli()

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
					console.log 'Thank you for using oauthd. Run "npm install", then "sudo grunt", then "oauthd start" to run your instance.'
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
								require('./plugins/install')("git@github.com:TheVinc/oauthd_default_plugin_auth.git", process.cwd() + "/" + results.name)
								# require('./plugins/install')("git@github.com:TheVinc/oauthd_default_plugin_me.git", process.cwd() + "/" + results.name)
								# require('./plugins/install')("git@github.com:TheVinc/oauthd_default_plugin_request.git", process.cwd() + "/" + results.name)
								# require('./plugins/install')("git@github.com:TheVinc/oauthd_default_plugin_front.git", process.cwd() + "/" + results.name)

# starts oauthd
if cli.argv._[0] == 'start'
	require('../../index').init()


# plugin management
if cli.argv._[0] == 'plugins'
	require('./plugins')(cli)
	