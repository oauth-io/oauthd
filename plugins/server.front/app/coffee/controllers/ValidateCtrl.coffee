#################################
# Validate account email + pass #
#################################


"use strict"
define [
	"app",
	"services/MenuService",
	"services/UserService"
	], (app) ->
		ValidateCtrl = ($rootScope, $timeout, $scope, $routeParams, MenuService, UserService, $location, $cookieStore) ->
			#MenuService.changed()
			#if UserService.isLogin()
			#	$location.path '/key-manager'
			# console.log "start isValidable"
			UserService.isValidable $routeParams.id, $routeParams.key, ((data) ->
				# console.log "check if validable", data
				$location.path '/404' if not data.data.is_validable and not data.data.is_updated

				if UserService.isLogin() and data.data.is_updated
					$rootScope.me.profile.mail = $rootScope.me.profile.mail_changed
					$rootScope.me.profile.mail_changed = null
					$rootScope.me.validated = '1'
					$location.path '/account'
				else if data.data.is_validable
					# $location.path '/signin'
					$scope.user =
						id: $routeParams.id
						key: $routeParams.key
						mail: data.data.mail
					UserService.validate $scope.user.id, $scope.user.key, ((data) ->
						$rootScope.me.profile.validated = "1"
						$timeout (->
							$rootScope.accessToken = $cookieStore.get 'accessToken'
							$location.path '/key-manager'
							$scope.$apply()
						), 5000
					), (error) ->
				else if not data.data.is_validable
					$location.path '/404'
			), (error) ->
				$location.path '/404'
			
		app.register.controller "ValidateCtrl", [
			"$rootScope"
			"$timeout"
			"$scope"
			"$routeParams"
			"MenuService"
			"UserService"
			"$location"
			"$cookieStore"
			ValidateCtrl
		]
		return

