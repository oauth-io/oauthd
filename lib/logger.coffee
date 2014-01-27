fs = require 'fs'

class Logger
	constructor: (@name) ->

	log: ->
		prepend = "### " + (new Date).toUTCString() + "\n"
		args = []
		for arg in arguments
			try
				args.push JSON.stringify arg
			catch e
				args.push '[[JSON str error]]'
		fs.appendFile __dirname + '/../logs/' + @name + '.log', prepend + args.join(' ') + "\n", 'utf8', ->

module.exports = Logger