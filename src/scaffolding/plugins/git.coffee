Q = require 'q'
fs = require 'fs'


module.exports = (env, plugin_name, fetch, cwd) ->
	createDefer = Q.defer()
	exec = env.exec
	cwd = cwd || process.cwd()

	plugin_location = cwd + '/plugins/' + plugin_name
	fetched = false
	if not fs.existsSync plugin_location + '/.git'
		createDefer.reject new Error('No .git file.')

	execGit = (commands, callback) ->
		full_command = 'cd ' + plugin_location + ';'
		if (fetch && not fetched)
			full_command += ' git fetch;'
			fetched = true
		for k,v of commands
			full_command += ' git ' + v + ';'
		exec full_command , () ->
			callback.apply null, arguments

	git =
		getCurrentVersion: () ->
			defer = Q.defer()
			execGit ['branch -v'], (error, stdout, stderr) ->
				return defer.reject error if error

				tag = stdout.match /\* \(detached from (.*)\)/
				tag = tag?[1]

				if not tag
					head = stdout.match /\* ([^\s]*)/
					head = head?[1]

					behind = stdout.match /\*.*\[behind (\d+)\]/
					behind = behind?[1]
				version = {}

				if tag?
					version.version = tag

					if tag.match /(\d+)\.(\d+)\.(\d+)/

						version.type = 'tag_n'
					else
						version.type = 'tag_a'
				else if head?
					version.version = head
					version.type = 'branch'
					if behind?
						version.uptodate = false
					else
						version.uptodate = true
				else
					version.version = 'No version information'
					version.type = 'unversionned'
				defer.resolve(version)
			defer.promise

		getVersionDetail: (version) ->
			version_detail = version.match /(\d+)\.(\d+)\.(\d+)/
			changes = version_detail[3]
			minor = version_detail[2]
			major = version_detail[1]

			major: major
			minor: minor
			changes: changes

		isNumericalVersion: (version) ->
			return version.match /(\d+)\.(\d+)\.(\d+)/

		isNumericalMask: (version) ->
			return version.match /^(\d+)\.(\d+|x)\.(\d+|x)$/

		compareVersions: (a, b) ->
			if a == b
				return 0
			vd_a = git.getVersionDetail a
			vd_b = git.getVersionDetail b
			if vd_a.major > vd_b.major
				return 1
			else if vd_a.major == vd_b.major
				if vd_a.minor > vd_b.minor
					return 1
				else if vd_a.minor == vd_b.minor
					if vd_a.changes > vd_b.changes
						return 1
					else
						return -1
				else
					return -1
			else
				return -1

		matchVersion: (mask, version) ->
			mask_ = mask.match /(\d+)\.(\d+|x)\.(\d+|x)/
			md =
				major: mask_[1]
				minor: mask_[2]
				changes: mask_[3]
			vd = git.getVersionDetail(version)
			if vd.major == md.major
				if vd.minor == md.minor || md.minor == 'x'
					if vd.changes ==  md.changes || md.changes == 'x'
						return true
					else
						return false
				else
					return false
			else
				return false


		getAllVersions: (mask) ->
			defer = Q.defer()
			execGit ['tag'], (error, stdout, stderr) ->
				tags = stdout.match /(\d+)\.(\d+)\.(\d+)/g
				matched_tags = []
				if mask
					for k,tag of tags
						if git.matchVersion mask, tag
							matched_tags.push tag
					tags = matched_tags
				tags.sort git.compareVersions
				defer.resolve(tags)
			defer.promise

		getAllTagsAndBranches: () ->
			defer = Q.defer()
			versions = {}
			execGit ['tag'], (error, stdout, stderr) ->
				versions.tags = stdout.match /[^\s]+/g
				execGit ['branch -a'], (error, stdout, stderr) ->
					branches = stdout.match /.+/g
					versions.branches = []
					for k, v of branches
						v = v.replace /^[\s]+/, ''
						match = v.match /[^\s]+\/[^\s]+\/([^\s]+).*/
						if match
							v = match[1]
						if (not v.match /detached/) and (not v.match /HEAD/)
							versions.branches.push v
					defer.resolve(versions)
			defer.promise


		getLatestVersion: (mask) ->
			defer = Q.defer()
			if mask.match /^(\d+)\.(\d+|x)\.(\d+|x)$/
				git.getAllVersions(mask)
					.then (versions) ->
						latest_version = versions[versions.length - 1]
						defer.resolve latest_version
			else
				defer.resolve mask
			defer.promise

		getVersionMask: () ->
			defer = Q.defer()

			env.plugins.info.getPluginsJson()
				.then (data) ->
					version_mask = data[plugin_name].version
					version_mask = 'master' if !(version_mask?) and data[plugin_name].repository
					defer.resolve version_mask
				.fail (e) ->
					defer.reject e

			defer.promise

		getRemote: () ->
			defer = Q.defer()
			env.plugins.info.getPluginsJson()
				.then (data) ->
					plugin_data = data[plugin_name]
					defer.resolve(plugin_data.repository)
				.fail (e) ->
					defer.reject e
			defer.promise

		pullBranch: (branch) ->
			defer = Q.defer()

			execGit ['pull origin ' + branch], (err, stdout, stderr) ->
				if not err?
					defer.resolve()
				else
					defer.reject()
			defer.promise

		checkout: (version) ->
			defer = Q.defer()
			execGit ['checkout ' + version], (err, stdout, stderr) ->
				if not err?
					defer.resolve()
				else
					defer.reject(new Error('The target version ' + version + ' does not seem to exist'))
			defer.promise

		isValidRepository: () ->
			defer = Q.defer()
			exec 'cd ' + process.cwd() + '/plugins/' + plugin_name + '; echo $(git rev-parse --show-toplevel)', (err, stdout, stderr) ->
				stdout = stdout.replace /[\s]/, ''
				defer.resolve(stdout == process.cwd() + '/plugins/' + plugin_name)
			defer.promise

	createDefer.resolve(git)
	createDefer.promise
