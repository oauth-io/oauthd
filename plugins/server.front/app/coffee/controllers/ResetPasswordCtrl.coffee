#################################
# Reset password 				#
#################################


"use strict"
define [
	"app",
	"services/MenuService"
	], (app) ->
		ResetPasswordCtrl = ($scope, $routeParams, MenuService, UserService, $location) ->
			UserService.isValidKey $routeParams.id, $routeParams.key, ((data) ->
				$location.path '/404' if not data.data.isValidKey
			), (error) ->
				$location.path '/404'

			$scope.validateForm = () ->
				$scope.error =
					status: ''
					message: ""

				user =
					pass: $('#pass').val()
					pass2: $('#pass2').val()

				if not user.pass or not user.pass2
					return false

				if user.pass == user.pass2

					UserService.resetPassword $routeParams.id, $routeParams.key, user.pass, ((data) ->

						UserService.login {
							mail: data.data.email
							pass: user.pass
						}, (data) ->
							$location.path '/key-manager'

					), (error) ->
						$scope.error =
							status: 'error'
							message: error
				else
					$scope.error =
						status: 'error'
						message: "Password1 != Password2"
			
		app.register.controller "ResetPasswordCtrl", [
			"$scope"
			"$routeParams"
			"MenuService"
			"UserService"
			"$location"
			ResetPasswordCtrl
		]
		return


