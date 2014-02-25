"use strict"
define [
	"app",
	"services/OAuthIOService",
	"services/MenuService"
	], (app) ->
		ContactUsCtrl = ($scope, $rootScope, OAuthIOService, MenuService) ->
			MenuService.changed()
			$scope.sendMail = ->

				$rootScope.error =
					state : false
					type : ''
					message : ''

				$scope.sent = false

				emailPattern = /// ^
					([\w\+.-]+)
					@
					([\w\+.-]+)
					\.
					([a-zA-Z.]{2,6})
					$ ///i

				name = $scope.mailForm.name.$viewValue
				email = $scope.mailForm.mail.$viewValue
				subject = $scope.mailForm.subject.$viewValue
				message = $scope.mailForm.message.$viewValue

				if not name? or name.length == 0
					$rootScope.error.state = true
					$rootScope.error.type = "SEND_MAIL"
					$rootScope.error.message = "Please, enter a name"
					return

				if not email? or !email.match emailPattern
					$rootScope.error.state = true
					$rootScope.error.type = "SEND_MAIL"
					$rootScope.error.message = "Please, enter a valid email"
					return

				if not subject? or subject.length == 0
					$rootScope.error.state = true
					$rootScope.error.type = "SEND_MAIL"
					$rootScope.error.message = "Please, enter a subject"
					return

				if not message? or message.length == 0
					$rootScope.error.state = true
					$rootScope.error.type = "SEND_MAIL"
					$rootScope.error.message = "Please, enter your message"
					return

				options =
					from:
						name: name
						email: email
					subject: subject
					body: message

				OAuthIOService.sendMail options, ((data) ->
					$scope.sent = true
				), (error) ->
					$rootScope.error.state = true
					$rootScope.error.type = "SEND_MAIL"
					$rootScope.error.message = "Service unavailable"
			
		app.register.controller "ContactUsCtrl", [
			"$scope"
			"$rootScope"
			"OAuthIOService" 
			"MenuService"
			ContactUsCtrl
		]
		return
