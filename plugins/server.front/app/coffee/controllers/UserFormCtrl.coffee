"use strict"
define ["app"], (app) ->
  UserFormCtrl = ($scope, $rootScope, $timeout, $http, $location, UserService, MenuService, $routeParams) ->
	MenuService.changed()
	if UserService.isLogin()
		$location.path '/key-manager'

	$('#socialConnect img').tooltip()

	if not $scope.info
		if document.location.hash.match /^#err=./
			$scope.info =
				status: 'error'
				message: (document.location.hash.match /^#err=(.+)$/)[1]
		$scope.info =
			status: ''
			message: ''

	if not $scope.signup
		$scope.signup =
			status:''
			message:''

	me =
		'facebook':
			url: '/me'
			name: 'name'
			mail: 'email'
		'twitter':
			url: '/1.1/account/verify_credentials.json'
			name: 'name'
		'google':
			url: '/oauth2/v1/userinfo'
			name: 'name'
			mail: 'email'
		'linkedin':
			url: '/v1/people/~:(id,email-address,first-name,last-name,headline)?format=json'
			name: ['firstName', 'lastName']
			mail: 'emailAddress',
			company: 'headline'
		'github':
			url: '/user'
			name: 'name'
			company: 'company'
			mail: 'email'
		'vk':
			url: '/method/getProfiles'
			name: ['first_name', 'last_name']
			path: 'response/0'
	$scope.hidePopup = -> $('.modal-backdrop').fadeOut 'fast'
	$scope.socialSignin = (provider) ->
		OAuth.initialize window.loginKey
		OAuth.popup provider, cache: true, (err, res) ->
			return false if err
			UserService.loginOAuth {
				access_token: res.access_token
				oauth_token: res.oauth_token
				oauth_token_secret: res.oauth_token_secret
			}, provider, ((path) ->
				$location.path '/key-manager'
			), (error) ->
				$scope.provider = provider
				$('#error-social').modal('show')
				return false

	$scope.connected = false

	$scope.finalize = ->
		$scope.loading = true

		$scope.canSignin = $scope.needEmail = $scope.success = false
		UserService.signupOAuth $scope.user, $scope.social, ((data) ->
			#console.log data.validated, not data.validated
			$scope.notValidated = not data.data.validated
			$scope.success = true
			$scope.loading = $scope.needEmail = false
		), (error) ->
			if error.message == "This email already exists"
				$scope.canSignin = $scope.success = false
				$scope.emailMessage = 2
				$scope.needEmail = true
			else if error.message == "This account is already linked to a user"
				$scope.canSignin = true
				$scope.needEmail = $scope.success = false
			else
				$scope.canSignin = $scope.success = false
				$scope.emailMessage = 1
				$scope.needEmail = true
			$scope.loading = false

	$scope.socialSignup = (provider) ->
		OAuth.initialize window.loginKey
		$scope.provider = provider
		OAuth.popup provider, cache: true, (err, res) ->
			return false if err
			res.get(me[provider].url).done (data)->

				if me[provider].path
					for eltname in me[provider].path.split '/'
						data = data[eltname]
				if Array.isArray me[provider].name
					name = (data[a] for a in me[provider].name).join ' '
					$scope.user.name = name
				else
					$scope.user.name = data[me[provider].name]
				$scope.user.mail = data[me[provider].mail]
				$scope.user.company = data[me[provider].company]

				$scope.social =
					provider: provider
					token: res.access_token
					oauth_token: res.oauth_token
					oauth_token_secret: res.oauth_token_secret
				$scope.$apply()

				$('#signup-modal').modal('show')
				$scope.finalize()
					#check if user exists
						#popup "connect me with {{provider}}"
					#popup "email" if not email verified in data
						#signup
							#popup email if email already taken
							#popup success -> Go to your dashboard (signin)

	if $routeParams.provider and $location.path().substr(0, 7) == '/signup'
		$scope.socialSignup $routeParams.provider
		$('.modal-backdrop').hide()

	if $routeParams.provider and $location.path().substr(0, 7) == '/signin'
		$scope.socialSignin $routeParams.provider
		$('.modal-backdrop').hide()

	$scope.signinSubmit = ->

	$scope.signupSubmit = ->
		#verif field
		UserService.register $scope.user, ((data) ->
			$scope.signupInfo =
				status: 'success'
		), (error) ->
			$scope.signupInfo =
				status: 'error'
				message: error.message

	$scope.userForm =
		template: "/templates/partials/userForm.html"
		mode: "Sign up"
		switchButtonText: "I already have an account !"
		pass:
			hide: false
		submit: ->

			$scope.info =
				status: ''
				message: ''
			$scope.signup =
				status: ''
				message: ''

			if $scope.userForm.mode == "Sign in"

				#signin
				UserService.login {mail:$('#mail').val(), pass:$('#pass').val()}, ((path)->
					$(window).off()
					$(document).off()
					$location.ga_skip = true;
					$location.path path
					# document.location.href = '/#' + path
					# document.location.reload()
				), (error) ->
					$scope.info =
						status: 'error'
						message: error?.message || 'Wrong email or password'

			else if $scope.userForm.mode == "Sign up"
				#signup
				UserService.register $('#mail').val(), ((data) ->
					$scope.signupInfo =
						status: 'success'
				), (error) ->
					$scope.signupInfo =
						status: 'error'
						message: error.message
			else
				#lost password
				UserService.lostPassword $('#mail').val(), ((data) ->
					$scope.info =
						status: 'info'
						message: 'We have sent password reset instructions to your email address'
				), (error) ->
					$scope.info =
						status: 'error'
						message: error.message


	if $location.path() == "/signin"
		$scope.userForm.mode = "Sign in"

	$scope.user =
		mail: ""
		pass: ""

	#change mode in User Form
	$scope.$watch 'userForm.mode', (newValue, oldValue) ->
		if newValue == 'Lost password'
			$scope.userForm.pass.hide = true
			$scope.userForm.switchButtonText = "I already have an account!"
		else if newValue == 'Sign up'
			$scope.userForm.pass.hide = true
			$scope.userForm.switchButtonText = "I already have an account!"
		else if newValue == 'Sign in'
			$scope.userForm.pass.hide = false
			$scope.userForm.switchButtonText = "I don't have an account yet!"


	#click lost password link
	$scope.lostPasswd = ->
		$scope.userForm.mode = "Lost password"
		$scope.info.status = ''

	#click cancel lost password
	$scope.cancelLostPasswd = ->
		$scope.userForm.mode = "Sign in"
		$scope.info.status = ''

	#click switch button (signin / signup)
	$scope.switchButton = ->
		if $scope.userForm.mode == "Sign up"
			$scope.userForm.mode = "Sign in"
		else
			$scope.userForm.mode = "Sign up"
		$scope.info.status = ''
		$scope.signup.status = ''
	
  app.register.controller "UserFormCtrl", [
    "$scope"
    "$rootScope"
    "$timeout"
    "$http"
    "$location"
    "UserService"
    "MenuService"
    "$routeParams"
    UserFormCtrl
  ]
  return
