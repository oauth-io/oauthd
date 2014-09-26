easy_cli = require 'easy-cli'
fs = require 'fs'
ncp = require 'ncp'
prompt = require 'prompt'

module.exports = (cli) ->
	cli.argv._.shift()

	if cli.argv._[0] is 'list'
		cli.argv._.shift()
		require('./list')()

	if cli.argv._[0] is 'uninstall' 
		cli.argv._.shift()
		plugin_name = ""
		for elt in cli.argv._
			if plugin_name != ""
				plugin_name += " "
			plugin_name += elt
		require('./uninstall')(plugin_name)

	if cli.argv._[0] is 'install'
		cli.argv._.shift()
		plugin_repo = cli.argv._[0]
		require('./install')(plugin_repo, process.cwd())
