easy_cli = require 'easy-cli'
fs = require 'fs'
ncp = require 'ncp'

cli = easy_cli()

# copies an instance basic folder in a new folder at current cwd
if cli.argv._[0] == 'init'
	fs.stat './project', (err, stats) ->
		if not stats
			fs.mkdirSync './project'
		ncp __dirname + '/../templates/basis_structure', process.cwd() + '/project', (err) ->
			return console.log err if err
			console.log 'done'

# starts oauthd
if cli.argv._[0] == 'start'
	require('../../index').init()
	