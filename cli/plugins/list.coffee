jf = require 'jsonfile'

module.exports = (cli) ->
	cli.argv._.shift()
	try
		jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
			throw err if err
			if not obj?
				console.log "There is no plugins installed yet!"
			else
				if Object.keys(obj).length > 0
					if Object.keys(obj).length > 1
						console.log "You have " + Object.keys(obj).length + " plugins installed: "
					else
						console.log "You have " + Object.keys(obj).length + " plugin installed: "
				else
						console.log "You have " + Object.keys(obj).length + " plugins installed. "
				for key, value of obj
					console.log "- '" + key + "'"
	catch e
			console.log 'An error occured: ' + e.message