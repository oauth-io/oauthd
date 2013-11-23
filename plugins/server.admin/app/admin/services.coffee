# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

apiRequest = ($http, $rootScope) -> (url, success, error, opts) ->
	opts ?= {}
	opts.url = oauthdconfig.base_api + "/" + url
	if opts.data
		opts.data = JSON.stringify opts.data
		opts.method ?= "POST"
	opts.method = opts.method?.toUpperCase() || "GET"
	opts.headers ?= {}
	if $rootScope.accessToken
		opts.headers.Authorization = "Bearer " + $rootScope.accessToken
	if opts.method is "POST" or opts.method is "PUT"
		opts.headers['Content-Type'] = 'application/json'
	req = $http(opts)
	req.success(success) if success
	req.error(error) if error
	return

hooks.config.push ->

	app.factory 'AdmService', ($http, $rootScope) ->
		api = apiRequest $http, $rootScope
		return me: (success, error) -> api 'me', success, error

	app.factory 'ProviderService', ($http, $rootScope) ->
		api = apiRequest $http, $rootScope
		return {
			list: (success, error) ->
				api 'providers', success, error

			get: (name, success, error) ->
				api 'providers/' + name + '?extend=true', success, error

			auth: (appKey, provider, success)->
				OAuth.initialize appKey
				OAuth.popup provider, success
		}


	app.factory 'AppService', ($http, $rootScope) ->
		api = apiRequest $http, $rootScope
		return {
			get: (key, success, error) ->
				api 'apps/' + key, success, error

			add: (app, success, error) ->
				api 'apps', success, error, data:
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
		}


	app.factory 'KeysetService', ($rootScope, $http) ->
		api = apiRequest $http, $rootScope
		return {
			get: (app, provider, success, error) ->
				api 'apps/' + app + '/keysets/' + provider, success, error

			add: (app, provider, keys, response_type, success, error) ->
				api 'apps/' + app + '/keysets/' + provider, success, error, data:
					parameters: keys
					response_type: response_type

			remove: (app, provider, success, error) ->
				api 'apps/' + app + '/keysets/' + provider, success, error, method:'delete'
		}
