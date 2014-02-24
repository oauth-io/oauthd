"use strict"
define ["services/routeResolver"], ->
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

      route = routeResolverProvider.route
      $routeProvider.when("/testlapin", route.resolve("Testlapin"))

      $routeProvider.when '/', route.resolve("IndexController", "/templates/landing-new.html")

      $routeProvider.when '/providers', route.resolve("IndexController", "/templates/providers.html", 'API Providers', 'Integrate 100+ OAuth providers in minutes, whether they use OAuth 1.0, OAuth 2.0 or similar')
     
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
  ]
  app
