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

global_err = /[\\#&]err=([^&]*)/.exec(document.location.hash)
if global_err
	document.location.hash = document.location.hash.replace(/&?err=[^&]*/, '');
	global_err = decodeURIComponent(global_err[1].replace(/\+/g, " "));

app = angular.module 'oauth', ['ui.bootstrap', 'ngDragDrop', 'ui.select2', 'ngCookies']

app.config([
	'$routeProvider'
	'$locationProvider'
	($routeProvider, $locationProvider) ->
		originalWhen = $routeProvider.when
		$routeProvider.when = ->
			arguments[0] = oauthdconfig.base + '/admin' + arguments[0]
			arguments[1].templateUrl = oauthdconfig.base + arguments[1].templateUrl if arguments[1]?.templateUrl
			originalWhen.apply($routeProvider, arguments)
		$routeProvider.when '',
			templateUrl: '/templates/signin.html'
			controller: 'SigninCtrl'
		$routeProvider.when '/error',
			templateUrl: '/templates/globalError.html'
			controller: 'ErrorCtrl'

		$routeProvider.otherwise redirectTo: '/admin'
		hooks.configRoutes $routeProvider, $locationProvider if hooks?.configRoutes

		$locationProvider.html5Mode true
]).config(['$httpProvider', ($httpProvider) ->
	interceptor = [
		'$rootScope'
		'$location'
		'$cookieStore'
		'$q'
		($rootScope, $location, $cookieStore, $q) ->

			success = (response) ->

				$rootScope.error =
					state : false
					message : ''
					type : ''

				return response

			error = (response) ->

				$rootScope.error =
					state : false
					message : ''
					type : ''

				if response.status == 401

					if $cookieStore.get 'accessToken'
						delete $rootScope.accessToken
						$cookieStore.remove 'accessToken'

					if $location.path() == "/"
						$rootScope.error.state = true
						$rootScope.error.message = "Invalid passphrase"

					$rootScope.authRequired = $location.path()
					$location.path '/'
					deferred = $q.defer()
					return deferred.promise


				# otherwise, default behaviour
				return $q.reject response

			return (promise) ->
				return promise.then success, error
	]
	$httpProvider.responseInterceptors.push interceptor
]).run ($rootScope, $location) ->
	$rootScope.baseurl = oauthdconfig.base
	$rootScope.adminurl = oauthdconfig.base + '/admin'
	locationpath = $location.path
	$location.path = ->
		if arguments.length == 0
			path = locationpath.call($location)
			if path.substr(0, $rootScope.adminurl.length) == $rootScope.adminurl.length
				path = path.substr($rootScope.adminurl.length)
			return path
		else
			arguments[0] = '' if arguments[0] == '/'
			return locationpath.call($location, $rootScope.adminurl + arguments[0])

if hooks?.config
	config() for config in hooks.config


app.factory 'UserService', ($http, $rootScope, $cookieStore) ->
	$rootScope.accessToken = $cookieStore.get 'accessToken'
	return $rootScope.UserService = {
		isLogin: -> $cookieStore.get('accessToken')?
	}

app.factory 'MenuService', ($rootScope, $location) ->
	$rootScope.selectedMenu = $location.path()
	return changed: -> $rootScope.selectedMenu = $location.path()

app.controller 'SigninCtrl', ($scope, $rootScope, $location, UserService, MenuService) ->
	if $rootScope.global_err
		document.location.reload()

	MenuService.changed()

	if global_err
		$scope.info =
			status: 'error'
			message: global_err

	if UserService.isLogin()
		if hooks?.configRoutes
			return $location.path '/key-manager'
		else
			document.location.reload()
	$scope.user = {}

	$scope.userForm =
		template: "/templates/userForm.html"

app.controller 'ErrorCtrl', ($scope, $rootScope) ->
	if not global_err
		return $location.path '/'

	$rootScope.global_err = global_err

	$scope.info =
		status: 'error'
		message: global_err