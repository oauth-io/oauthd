define [
	'utilities/apiRequest'
	], (apiRequest) ->
		AppService = ($http, $rootScope) ->
			api = apiRequest $http, $rootScope
			return {
				get: (key, success, error) ->
					api 'apps/' + key, success, error

				loadApps: (apps, success, error) ->
					$rootScope.me.apps = []
					$rootScope.me.totalUsers = 0
					$rootScope.me.keysets = []
					for i of apps
						@loadApp apps[i], ((res) ->
							if parseInt(i) + 1 == parseInt(apps.length)
								success() if success
						), error


				loadApp: (key, success, error) ->
					@get key, ((app) =>
						#console.log app.data

						app.data.keysets?.sort()
						app.data.keys = {}
						app.data.response_type = {}
						app.data.showKeys = false

						app.data.secret = ""

						$rootScope.me.keysets = [] if not $rootScope.me.keysets
						$rootScope.me.keysets.add app.data.keysets
						$rootScope.me.keysets = $rootScope.me.keysets.unique()

						@getTotalUsers app.data.key, (res) ->
							app.data.totalUsers = parseInt(res.data) || 0
							$rootScope.me.apps = [] if not $rootScope.me.apps
							$rootScope.me.apps.push app.data
							$rootScope.me.totalUsers += parseInt(res.data) || 0
							success() if success
						, error
					), error

				add: (app, success, error) ->
					api 'apps', ((res) =>
						console.log res.data
						@loadApp res.data.key, success, error
					), error, data:
						name: app.name
						domains: app.domains

				edit: (key, app, success, error) ->
					api 'apps/' + key, success, error, data:
						name: app.name
						domains: app.domains

				remove: (key, success, error) ->
					api 'apps/' + key, success, error, method:'delete'

				resetKey: (key, success, error) ->
					api 'apps/' + key + '/reset', success, error, method:'post'

				getTotal: (key, success, error) ->
					api 'users/app/' + key, success, error

				getTotalUsers: (key, success, error) ->
					api 'users/app/' + key + '/users', success, error

				# stats: (key, provider, success, error) ->
				# 	api 'apps/' + key + '/stats', success, error
			}
		return ['$http', '$rootScope', AppService]