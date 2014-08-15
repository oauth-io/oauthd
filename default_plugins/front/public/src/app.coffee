


app = angular.module("oauthd", ["ui.router"]).config(["$stateProvider", "$urlRouterProvider",
	($stateProvider, $urlRouterProvider) ->
		$stateProvider.state 'login',
			url: '/login',
			templateUrl: 'templates/login.html'
			controller: 'LoginCtrl'
])

require('./filters/filters') app

require('./controllers/LoginCtrl') app