jf = require 'jsonfile'
Q = require 'q'

module.exports = () ->
	# plugin_repo_str = plugin_repo.split("^")
	# plugin_repo = plugin_repo_str[0]
	# tag_name = null
	# if plugin_repo_str.length > 1
	# 	tag_name = plugin_repo_str[1]
	# env.debug "Cloning " + plugin_repo.red
	# command = 'cd ' + temp_location + '; git clone ' + plugin_repo + ' ' + temp_location
	# if force 
	# 	command += '; git checkout tags/' + tag_name
			
	defer = Q.defer()
	# jf.readFile process.cwd() + '/plugins.json', (err, obj) ->
	# 	return defer.reject err if err
	# 	plugins = []
	# 	if obj?
	# 		plugins = Object.keys(obj)
	# 	defer.resolve(plugins)
	defer.resolve()
	defer.promise