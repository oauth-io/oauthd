Q = require 'q'

colors = require 'colors'
sugar = require 'sugar'

module.exports = (env) ->
	
	exec = env.exec
	
	(plugin_name) ->
		defer = Q.defer()
		env.plugins.git(plugin_name, true)
			.then (plugin_git) ->
				plugin_git.isValidRepository()
					.then (valid) ->
						if (not valid)
							defer.reject new Error 'No git remote for plugin ' + plugin_name
						else
							current_v = undefined
							cv_info = undefined
							latest_v = undefined
							update = false
							plugin_git.getCurrentVersion()
								.then (v) ->
									plugin_git.getVersionMask()
										.then (mask) ->
											current_v = v.version
											cv_info = v
											if plugin_git.isNumericalMask(mask)
												plugin_git.getLatestVersion(mask)
													.then (latest_v) ->
														target_version = latest_v
														plugin_git.checkout target_version
															.then () ->
																return defer.resolve(target_version)
															.fail (e) ->
																return defer.reject new Error('No target version found for mask \'' + mask + '\'')
											else
												plugin_git.checkout mask
													.then () ->
														return defer.resolve(mask)
													.fail (e) ->
														return defer.reject new Error('Target version ' + mask + ' does not exist')
								.fail (e) ->
									defer.reject e
			.fail (err) ->
				defer.reject err
		defer.promise
