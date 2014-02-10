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

window.hooks = config:[]

hooks.configRoutes = ($routeProvider, $locationProvider) ->
	$routeProvider.when '/license',
		templateUrl: '/admin/templates/license.html'
		controller: 'LicenseCtrl'

	$routeProvider.when '/about',
		templateUrl: '/admin/templates/about.html'
		controller: 'AboutCtrl'

	$routeProvider.when '/contact-us',
		templateUrl: '/admin/templates/contact-us.html'
		controller: 'ContactUsCtrl'

	$routeProvider.when '/logout',
		templateUrl: '/templates/signin.html'
		controller: 'LogoutCtrl'

	$routeProvider.when '/key-manager',
		templateUrl: '/admin/templates/key-manager.html'
		controller: 'ApiKeyManagerCtrl'

	$routeProvider.when '/app-create',
		templateUrl: '/admin/templates/app-create.html'
		controller: 'AppCtrl'

	$routeProvider.when '/404',
		templateUrl: '/admin/templates/404.html'
		controller: 'NotFoundCtrl'

	$routeProvider.otherwise redirectTo: '/404'