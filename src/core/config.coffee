
module.exports = (env) ->
	Path = require 'path'
	Url = require 'url'

	# fetches the root config module
	config = require '../../config'
	
	config.rootdir = Path.normalize __dirname + '/../..'
	config.root = Path.normalize __dirname + '/../..'

	config.base = Path.resolve '/', config.base
	config.relbase = config.base
	config.base = '' if config.base == '/'
	config.base_api = Path.resolve '/', config.base_api
	config.url = Url.parse config.host_url
	config.bootTime = new Date

	config