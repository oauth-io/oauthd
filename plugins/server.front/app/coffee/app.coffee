"use strict"
define [
	"filters/filters",
	"directives/directives",
	"utilities/routeResolver",
	"utilities/servicesModule",
	"utilities/controllersModule"
	], (registerFilters, registerDirectives, routeResolver, registerServices, registerControllers) ->
		route = {}
		app = angular.module("oauth", [
			"routeResolverServices"
			"ui.bootstrap"
			"ngDragDrop"
			"ui.select2"
			"ngCookies"
		])
		app.config [
			"$routeProvider"
			"$locationProvider"
			"routeResolverProvider"
			"$controllerProvider"
			"$compileProvider"
			"$filterProvider"
			"$provide"
			($routeProvider, $locationProvider, routeResolverProvider, $controllerProvider, $compileProvider, $filterProvider, $provide) ->
				app.register =
					controller: $controllerProvider.register
					directive: $compileProvider.directive
					filter: $filterProvider.register
					factory: $provide.factory
					service: $provide.service


				## This registers services, filters and directives prior to
				## other actions
				registerServices app
				registerFilters app
				registerDirectives app
				registerControllers app
				
				route = routeResolverProvider.route
				
				##This registers all the routes 
				$routeProvider.when '/',
					templateUrl: '/templates/landing-new.html'
					controller: 'IndexCtrl'

				$routeProvider.when '/providers',
					templateUrl: '/templates/providers.html'
					controller: 'ProviderCtrl'
					title: 'API Providers'
					desc: 'Integrate 100+ OAuth providers in minutes, whether they use OAuth 1.0, OAuth 2.0 or similar'

				$routeProvider.when '/wishlist',
					templateUrl: '/templates/wishlist.html'
					controller: 'WishlistCtrl'
					title: 'API wishlist'
					desc: 'OAuth.io supports 100+ API providers. Just vote for a provider in the wishlist or post a pull request on GitHub !'

				$routeProvider.when '/terms',
					templateUrl: '/templates/terms.html'
					controller: 'TermsCtrl'
					title: 'Terms of service'
					desc: 'Webshell SAS provides OAuth.io and the services described here to provide an OAuth server to authenticate end user on third party sites.'

				$routeProvider.when '/about',
					templateUrl: '/templates/about.html'
					controller: 'AboutCtrl'
					title: 'About the team'

				$routeProvider.when '/docs',
					templateUrl: '/templates/docs.html'
					controller: 'DocsCtrl'
					title: 'Documentation'
					desc: 'Integrate 100+ OAuth providers in minutes. Setup your keys, install oauth.js, and you are ready to play !'

				$routeProvider.when '/faq',
					templateUrl: '/templates/faq.html'
					controller: 'DocsCtrl'
					title: 'Frequently Asked Question'

				$routeProvider.when '/docs/:page',
					templateUrl: '/templates/docs.html'
					controller: 'DocsCtrl'
					title: 'Documentation'

				$routeProvider.when '/help',
					templateUrl: '/templates/help.html'
					controller: 'HelpCtrl'
					title: 'Support'
					desc: 'Check out the documentation, faq, feebacks or blog. If you still have a question, you can contact the OAuth io support team'

				$routeProvider.when '/pricing',
					templateUrl: '/templates/pricing.html'
					controller: 'PricingCtrl'
					title: 'Pricing'

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
					title: 'Contact us'

				$routeProvider.when '/features',
					templateUrl: '/templates/features.html'
					controller: 'FeaturesCtrl'

				$routeProvider.when '/feedback',
					templateUrl: '/templates/feedback.html'
					controller: 'HelpCtrl'
					title: 'Feedbacks'

				$routeProvider.when '/imprint',
					templateUrl: '/templates/imprint.html'
					controller: 'ImprintCtrl'
					title: 'Informations'
					desc: 'OAuth.io is a offered by Webshell SAS, 86 Rue de Paris, 91400 ORSAY. Phone: +33(0)614945903, email: team@webshell.io'

				$routeProvider.when '/signin',
					templateUrl: '/templates/signin.html'
					controller: 'UserFormCtrl'
					title: 'Sign in'

				$routeProvider.when '/signin/:provider',
					templateUrl: '/templates/signin.html'
					controller: 'UserFormCtrl'
					title: 'Sign in'

				$routeProvider.when '/signup',
					templateUrl: '/templates/signup.html'
					controller: 'UserFormCtrl'
					title: 'Register'

				$routeProvider.when '/signup/:provider',
					templateUrl: '/templates/signup.html'
					controller: 'UserFormCtrl'
					title: 'Register'

				$routeProvider.when '/account',
					templateUrl: '/templates/user-profile.html'
					controller: 'UserProfileCtrl'
					title: 'My account'

				$routeProvider.when '/logout',
					templateUrl: '/templates/blank.html'
					controller: 'LogoutCtrl'

				$routeProvider.when '/key-manager',
					templateUrl: '/templates/key-manager.html'
					controller: 'ApiKeyManagerCtrl'
					title: 'Key manager'

				$routeProvider.when '/provider/:provider',
					templateUrl: '/templates/provider.html'
					controller: 'ProviderPageCtrl'

				$routeProvider.when '/provider/:provider/app',
					templateUrl: '/templates/provider.html'
					controller: 'ProviderAppCtrl'

				$routeProvider.when '/provider/:provider/app/:app',
					templateUrl: '/templates/provider.html'
					controller: 'ProviderAppKeyCtrl'

				$routeProvider.when '/provider/:provider/samples',
					templateUrl: '/templates/provider.html'
					controller: 'ProviderSampleCtrl'

				$routeProvider.when '/provider/:provider/app/:app/samples',
					templateUrl: '/templates/provider.html'
					controller: 'ProviderSampleCtrl'

				$routeProvider.when '/app-create',
					templateUrl: '/templates/app-create.html'
					controller: 'AppCtrl'
					title: 'App creation'

				$routeProvider.when '/app-create/:provider',
					templateUrl: '/templates/app-create.html'
					controller: 'AppCtrl'
					title: 'App creation'

				$routeProvider.when '/validate/:id/:key',
					templateUrl: '/templates/user-validate.html'
					controller: 'ValidateCtrl'
					title: 'Account validation'

				$routeProvider.when '/resetpassword/:id/:key',
					templateUrl: '/templates/user-resetpassword.html'
					controller: 'ResetPasswordCtrl'
					title: 'Password reset'

				$routeProvider.when '/404',
					templateUrl: '/templates/404.html'
					controller: 'NotFoundCtrl'
					title: '404 not found'
				
				# $routeProvider.when '/',
				# 	route.resolve("Index",
				# 		"/templates/landing-new.html")

				# $routeProvider.when '/providers',
				# 	route.resolve("Provider",
				# 		"/templates/providers.html",
				# 		'API Providers',
				# 		'Integrate 100+ OAuth providers in minutes, whether they use OAuth 1.0, OAuth 2.0 or similar')
			 
				# $routeProvider.when '/wishlist',
				# 	route.resolve("Wishlist", 
				# 		"/templates/wishlist.html", 
				# 		'API wishlist', 
				# 		'OAuth.io supports 100+ API providers. Just vote for a provider in the wishlist or post a pull request on GitHub !')
			 
				# $routeProvider.when '/terms',
				# 	route.resolve("Terms", 
				# 		"/templates/terms.html", 
				# 		'Terms of service', 
				# 		'Webshell SAS provides OAuth.io and the services described here to provide an OAuth server to authenticate end user on third party sites.')
		
				# $routeProvider.when '/about',
				# 	route.resolve("About", 
				# 		"/templates/about.html", 
				# 		'About the team')

				# $routeProvider.when '/docs',
				# 	route.resolve("Docs", 
				# 		"/templates/docs.html", 
				# 		'Documentation', 
				# 		'Integrate 100+ OAuth providers in minutes. Setup your keys, install oauth.js, and you are ready to play !')

				# $routeProvider.when '/faq',
				# 	route.resolve("Docs", 
				# 		"/templates/faq.html", 
				# 		'Frequently Asked Question')

				# $routeProvider.when '/docs/:page',
				# 	route.resolve("Docs", 
				# 		"/templates/docs.html", 
				# 		'Documentation')

				# $routeProvider.when '/help',
				# 	route.resolve("Help", 
				# 		"/templates/help.html", 
				# 		'Support', 
				# 		'Check out the documentation, faq, feebacks or blog. If you still have a question, you can contact the OAuth io support team')

				# $routeProvider.when '/pricing',
				# 	route.resolve("Pricing", 
				# 		"/templates/pricing.html", 
				# 		'Pricing')

				# $routeProvider.when '/pricing/unsubscribe',
				# 	route.resolve("Pricing", 
				# 		"/templates/unsubscribe-confirm.html")

				# $routeProvider.when '/payment/customer',
				# 	route.resolve("Payment",
				# 		'/templates/payment.html')

				# $routeProvider.when '/payment/confirm',
				# 	route.resolve("Payment", 
				# 			"/templates/payment-confirm.html")

				# $routeProvider.when '/payment/:name/success',
				# 	route.resolve("Payment", 
				# 			"/templates/successpayment.html")
			
				# $routeProvider.when '/editor',
				# 	route.resolve("Editor", 
				# 			"/templates/editor.html")

				# $routeProvider.when '/contact-us',
				# 	route.resolve("Contact", 
				# 		"/templates/contact-us.html",
				# 		"Contact us")

				# $routeProvider.when '/features',
				# 	route.resolve("Features", 
				# 		"/templates/features.html")

				# $routeProvider.when '/feedback',
				# 	route.resolve("Help", 
				# 		"/templates/feedback.html",
				# 		"Feedbacks")

				# $routeProvider.when '/imprint',
				# 	route.resolve("Imprint", 
				# 			"/templates/imprint.html", 
				# 			'Informations', 
				# 			'OAuth.io is a offered by Webshell SAS, 86 Rue de Paris, 91400 ORSAY. Phone: +33(0)614945903, email: team@webshell.io')
			
				# $routeProvider.when '/signin',
				# 	route.resolve("UserForm", 
				# 		"/templates/signin.html",
				# 		"Sign in")

				# $routeProvider.when '/signin/:provider',
				# 	route.resolve("UserForm", 
				# 		"/templates/signin.html",
				# 		"Sign in")

				# $routeProvider.when '/signup',
				# 	route.resolve("UserForm", 
				# 		"/templates/signup.html",
				# 		"Register")

				# $routeProvider.when '/signup/:provider',
				# 	route.resolve("UserForm", 
				# 		"/templates/signup.html",
				# 		"Register")

				# $routeProvider.when '/account',
				# 	route.resolve("UserProfile", 
				# 		"/templates/user-profile.html",
				# 		"My account")

				# $routeProvider.when '/logout',
				# 	route.resolve("Logout", 
				# 		"/templates/blank.html")
				
				# $routeProvider.when '/key-manager',
				# 	route.resolve("ApiKeyManager", 
				# 		"/templates/key-manager.html",
				# 		"Key manager")
				
				# $routeProvider.when '/provider/:provider',
				# 	route.resolve("ProviderPage", 
				# 		"/templates/provider.html")

				# $routeProvider.when '/provider/:provider/app',
				# 	route.resolve("ProviderApp", 
				# 		"/templates/provider.html")

				# $routeProvider.when '/provider/:provider/app/:app',
				# 	route.resolve("ProviderAppKey", 
				# 		"/templates/provider.html")

				# $routeProvider.when '/provider/:provider/samples',
				# 	route.resolve("ProviderSample", 
				# 		"/templates/provider.html")

				# $routeProvider.when '/provider/:provider/app/:app/samples',
				# 	route.resolve("ProviderSample", 
				# 		"/templates/provider.html") 

				# $routeProvider.when '/app-create',
				# 	route.resolve("App", 
				# 		"/templates/app-create.html",
				# 		"App creation")

				# $routeProvider.when '/app-create/:provider',
				# 	route.resolve("App", 
				# 		"/templates/app-create.html",
				# 		"App creation")

				# $routeProvider.when '/validate/:id/:key',
				# 	route.resolve("Validate", 
				# 		"/templates/user-validate.html",
				# 		"Account validation")

				# $routeProvider.when '/resetpassword/:id/:key',
				# 	route.resolve("ResetPassword", 
				# 		"/templates/user-resetpassword.html",
				# 		"Password reset")

				# $routeProvider.when '/404',
				# 	route.resolve("NotFound", 
				# 		"/templates/404.html",
				# 		"404 not found")

				hooks.configRoutes $routeProvider, $locationProvider if hooks?.configRoutes
				$routeProvider.otherwise redirectTo: '/404'

				$locationProvider.html5Mode true
		]

		
		app.config(['$httpProvider', ($httpProvider) ->
			interceptor = [
				'$rootScope'
				'$location'
				'$cookieStore'
				'$q'
				($rootScope, $location, $cookieStore, $q) ->

					$rootScope.$on '$routeChangeSuccess', (event, current, previous) =>
						$rootScope.pageTitle = 'OAuth.io - ' + (current.$$route?.title || 'OAuth that just works.')
						$rootScope.pageDesc = (current.$$route?.desc || 'OAuth has never been this easy. Put only 3 lines of codes and you are done in less than 90 seconds !')

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
		]).run ['$rootScope', '$location', 'UserService', '$modal', 'NotificationService', '$timeout', 'InspectorService', ($rootScope, $location, UserService, $modal, NotificationService, $timeout, InspectorService) ->
			checkLimitation = ->
				return true if $rootScope.me.apps?.length >= $rootScope.me.plan?.nbApp or $rootScope.me.totalUsers? >= $rootScope.me.plan?.nbUsers or $rootScope.me.keysets?.length >= $rootScope.me.plan?.nbProvider
				return false
			checkValidated = ->
				return false if $rootScope.me.profile.validated == "2"
				return true

			initializeNotification = ->
				NotificationService.clear()
				return false if not $rootScope.me
				if checkLimitation()
					NotificationService.push
						type: 'upgrade',
						href: '/pricing',
						title: "Time to upgrade",
						content: 'You\'ve reached the limit. To go further: <a href="/pricing">upgrade your plan</a>.'
				if not checkValidated()
					NotificationService.push
						type: 'validate'
						title: 'Email validation'
						content: 'We\'ve sent you an email to validate your account. Please open the link inside to validate your account'
				$('#notification').popover()

			UserService.initialize ->

			$rootScope.openNotifications = ->
				NotificationService.open()

			$rootScope.$watch 'me', (-> $timeout initializeNotification, 500), true

			$rootScope.location = $location.path()
		]
		hooks.config() if hooks?.config
		
		app
