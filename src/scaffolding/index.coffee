# options:
# opts.console (true/false)

exec = require('child_process').exec
fs = require 'fs'
jf = require 'jsonfile'
ncp = require 'ncp'

module.exports = (opts) ->
	opts = opts || {}
	scaffolding_env = {
		debug: () ->
			if (opts.console)
				console.log.apply null, arguments
			else
				return
		exec: exec,
		fs: fs,
		ncp: ncp,
		jsonfile: jf
	}

	scaffolding_env.plugins = require('./plugins')(scaffolding_env)
	scaffolding_env.init = require('./init')(scaffolding_env)
	scaffolding_env.compile = require('./compile')(scaffolding_env)

	scaffolding_env


