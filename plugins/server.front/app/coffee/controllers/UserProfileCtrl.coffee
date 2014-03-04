"use strict"
define [
	"services/MenuService",
	"services/UserService"
	"services/AppService"
	], () ->
		UserProfileCtrl = ($rootScope, $scope, $routeParams, $location, $timeout, MenuService, UserService, AppService) ->
			MenuService.changed()
			if not UserService.isLogin()
				$location.path '/'

			$scope.changeTab = (tab) ->
				if tab == 'payment'
					$scope.loading = true
					$scope.subscriptions = null
					UserService.getSubscriptions (success) ->
						$scope.subscriptions = success.data.subscriptions
						$scope.loading = false
					, (error) ->
						$scope.loading = false
						console.log error

				$scope.accountView = '/templates/partials/account/' + tab + '.html'
				$scope.tab = tab

			$scope.changeTab 'general'
			$scope.sync = {}
			$scope.syncProvider = (provider)->
				OAuth.initialize window.loginKey
				OAuth.popup provider, (err, success) =>
					return null if err
					tokens =
						token: success.access_token
						oauth_token: success.oauth_token
						oauth_token_secret: success.oauth_token_secret

					UserService.sync provider, tokens, ->
						$scope.sync[provider] = true

			UserService.getSync (providers) ->
				$scope.sync = {}
				$scope.sync[provider] = true for provider in providers.data
				$scope.user = $rootScope.me.profile

			$scope.changeEmailState = false
			$scope.emailSent = false
			$scope.updateDone = false

			$scope.changeEmail = ->
				$scope.changeEmailState = true
				$('#email-input').removeAttr('disabled')

			$scope.cancelEmailUpdate = ->
				UserService.cancelUpdateEmail ((success) ->
					$rootScope.me.profile.email_changed = null
				), (error) ->

			$scope.changePasswordButton = ->
				$scope.accountView = '/templates/partials/account/update_password.html'

			$scope.cancelChangePasswordButton = ->
				$scope.accountView = '/templates/partials/account/settings.html'

			$scope.updatePassword = (currentPassword, newPassword, newPassword2) ->
				if newPassword is newPassword2
					UserService.updatePassword currentPassword, newPassword, ((success) ->
						$scope.cancelChangePasswordButton()
					), (error) ->
						$scope.errorPassword = error
				else
					$scope.errorPassword =
						status: "fail"

			$rootScope.$watch 'loading', (newval) ->
				if newval == false
					$scope.user = Object.clone $rootScope.me.profile

			$scope.updateEmail = ->
				UserService.updateEmail $scope.user.mail, ((success) ->
					$('#email-input').attr('disabled', 'disabled')
					$scope.changeEmailState = false
					$rootScope.me.profile.mail_changed = $scope.user.mail
					$scope.user.mail = $rootScope.me.profile.mail
				), (error) ->
					if error.message is "Your email has not changed"
						$('#email-input').attr('disabled', 'disabled')
						$scope.changeEmailState = false


			$scope.update = ->
				$scope.updateDone = false
				UserService.update $scope.user, (success) ->
					$rootScope.me.profile.name = success.data.name
					$scope.updateDone = true
					$rootScope.me.profile.location = success.data.location
					$rootScope.me.profile.company = success.data.company
					$rootScope.me.profile.website = success.data.website
				, (error) ->
					$scope.error =
						state : true
						message : error.message

			$scope.onDismiss = ->
				$scope.error =
					state : false
			
		return [
			"$rootScope",
			"$scope",
			"$routeParams",
			"$location",
			"$timeout",
			"MenuService",
			"UserService",
			"AppService",
			UserProfileCtrl
		]