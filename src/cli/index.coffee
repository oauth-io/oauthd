exec = require('child_process').exec
easy_cli = require 'easy-cli'
ncp = require 'ncp'
cli = easy_cli()
scaffolding = require('../scaffolding')({ console: true })

endOfInit = (name, showGrunt) ->
	info = 'Running npm install'
	command = 'cd '+ name + ' && npm install'
	if showGrunt
		info += ' and grunt.'
		command += ' && grunt'
	else
		info += '.'
	console.log info.green + ' Please wait, this might take up to a few minutes.'.yellow
	exec = require('child_process').exec
	exec command, (error, stdout, stderr) ->
		if error
			console.log "Error running command \"" + command + "\"."
			console.log error
		else
			console.log 'Done'
			r_command = 'cd ' + name + ' && oauthd start'
			console.log 'Thank you for using oauthd. Run ' + r_command.green + ' to start the instance'


# copies an instance basic folder in a new folder at current cwd
if cli.argv._[0] == 'init'
	scaffolding.init()
	.then (name) ->
		endOfInit(name, true)
	.fail (err) ->
		console.log 'An error occured: '.red + e.message.yellow
		# console.log 'An error occured: '.red + err.yellow

# starts oauthd
if cli.argv._[0] == 'start'
	require('../oauthd').init()

# plugin management
if cli.argv._[0] == 'plugins'
	require('./plugins')(cli)
	