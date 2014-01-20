app = angular.module 'oauth', ['ui.bootstrap', 'ngDragDrop', 'ui.select2', 'ngCookies']

app.config([
	'$routeProvider'
	'$locationProvider'
	($routeProvider, $locationProvider) ->
		$routeProvider.when '/',
			templateUrl: '/templates/landing-new.html'
			controller: 'IndexCtrl'

		$routeProvider.when '/home',
			templateUrl: '/templates/landing-new.html'
			controller: 'LandingCtrl'

		$routeProvider.when '/providers',
			templateUrl: '/templates/providers.html'
			controller: 'ProviderCtrl'

		$routeProvider.when '/wishlist',
			templateUrl: '/templates/wishlist.html'
			controller: 'WishlistCtrl'

		$routeProvider.when '/terms',
			templateUrl: '/templates/terms.html'
			controller: 'TermsCtrl'

		$routeProvider.when '/about',
			templateUrl: '/templates/about.html'
			controller: 'AboutCtrl'

		$routeProvider.when '/docs',
			templateUrl: '/templates/docs.html'
			controller: 'DocsCtrl'

		$routeProvider.when '/faq',
			templateUrl: '/templates/faq.html'
			controller: 'DocsCtrl'

		$routeProvider.when '/docs/:page',
			templateUrl: '/templates/docs.html'
			controller: 'DocsCtrl'

		$routeProvider.when '/help',
			templateUrl: '/templates/help.html'
			controller: 'HelpCtrl'

		$routeProvider.when '/pricing',
			templateUrl: '/templates/pricing.html'
			controller: 'PricingCtrl'

		$routeProvider.when '/pricing/unsubscribe',
			templateUrl: '/templates/unsubscribe-confirm.html'
			controller: 'PricingCtrl'

		$routeProvider.when '/payment/customer',
			templateUrl: '/templates/payment.html'
			controller: 'PaymentCtrl'

		$routeProvider.when '/payment/confirm',
			templateUrl: '/templates/payment-confirm.html'
			controller: 'PaymentCtrl'

		$routeProvider.when '/payment/:name/success',
			templateUrl: '/templates/successpayment.html'
			controller: 'PaymentCtrl'

		$routeProvider.when '/editor',
			templateUrl: '/templates/editor.html'
			controller: 'EditorCtrl'

		$routeProvider.when '/contact-us',
			templateUrl: '/templates/contact-us.html'
			controller: 'ContactUsCtrl'

		$routeProvider.when '/features',
			templateUrl: '/templates/features.html'
			controller: 'FeaturesCtrl'

		$routeProvider.when '/feedback',
			templateUrl: '/templates/feedback.html'
			controller: 'HelpCtrl'

		$routeProvider.when '/imprint',
			templateUrl: '/templates/imprint.html'
			controller: 'ImprintCtrl'

		$routeProvider.when '/signin',
			templateUrl: '/templates/signin.html'
			controller: 'UserFormCtrl'

		$routeProvider.when '/signup',
			templateUrl: '/templates/signup.html'
			controller: 'UserFormCtrl'

		$routeProvider.when '/account',
			templateUrl: '/templates/user-profile.html'
			controller: 'UserProfileCtrl'

		$routeProvider.when '/logout',
			templateUrl: '/templates/landing.html'
			controller: 'LogoutCtrl'

		$routeProvider.when '/key-manager',
			templateUrl: '/templates/key-manager.html'
			controller: 'ApiKeyManagerCtrl'

		$routeProvider.when '/key-manager/:provider',
			templateUrl: '/templates/key-manager.html'
			controller: 'ApiKeyManagerCtrl'

		$routeProvider.when '/app-create',
			templateUrl: '/templates/app-create.html'
			controller: 'AppCtrl'

		$routeProvider.when '/validate/:id/:key',
			templateUrl: '/templates/user-validate.html'
			controller: 'ValidateCtrl'

		$routeProvider.when '/resetpassword/:id/:key',
			templateUrl: '/templates/user-resetpassword.html'
			controller: 'ResetPasswordCtrl'

		$routeProvider.when '/404',
			templateUrl: '/templates/404.html'
			controller: 'NotFoundCtrl'

		hooks.configRoutes $routeProvider, $locationProvider if hooks?.configRoutes
		$routeProvider.otherwise redirectTo: '/404'

		$locationProvider.html5Mode true
]).config ['$httpProvider', ($httpProvider) ->
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

					if $location.path() == "/signin"
						$rootScope.error.state = true
						$rootScope.error.message = "Email or password incorrect"

					$rootScope.authRequired = $location.path()
					$location.path('/signin').replace()
					deferred = $q.defer()
					return deferred.promise


				# otherwise, default behaviour
				return $q.reject response

			return (promise) ->
				return promise.then success, error
	]
	$httpProvider.responseInterceptors.push interceptor
]
hooks.config() if hooks?.config
