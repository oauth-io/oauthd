Q = require 'q'

colors = require 'colors'
sugar = require 'sugar'

module.exports = (env) ->
	exec = env.exec
	(plugin_name) ->
		defer = Q.defer()
		plugin_git = env.plugins.git(plugin_name, false)
		current_v = undefined
		cv_info = undefined
		latest_v = undefined
		update = false
		plugin_git.getCurrentVersion()
			.then (v) ->
				current_v = v.version
				cv_info = v
				if cv_info.type == 'tag_n'
					plugin_git.getVersionMask()
						.then (mask) ->
							return plugin_git.getLatestVersion(mask)
						.then (v) ->
							latest_v = v
							comparison = plugin_git.compareVersions latest_v, current_v
							if comparison > 0
								plugin_git.checkout latest_v
									.then () ->
										defer.resolve(true)
									.fail (e) ->
										defer.reject(e)
							else
								defer.resolve(false)
				else if cv_info.type == 'branch'
					if not cv_info.uptodate
						plugin_git.pullBranch cv_info.version
							.then () ->
								defer.resolve(true)
							.fail (e) ->
								defer.reject(e)
					else
						defer.resolve false
				else
					defer.resolve false
			.fail (e) ->
				defer.reject e
		defer.promise
