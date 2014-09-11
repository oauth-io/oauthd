easy_cli = require 'easy-cli'
fs = require 'fs'
ncp = require 'ncp'
prompt = require 'prompt'

module.exports = (cli) ->
	cli.argv._.shift()

	if cli.argv._[0] == 'list'
		return
	else if cli.argv._[0] == 'install'
		require('./install')(cli)