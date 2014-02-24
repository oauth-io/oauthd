"use strict"

###########################
# Landing page Controller #
###########################

define ["app"], (app) ->
  IndexCtrl = ($scope, $rootScope, $http, $location, UserService, MenuService) ->
	MenuService.changed()
	# if UserService.isLogin()
	# 	$location.path '/key-manager'

	$scope.selectedProvider = 'facebook'
	$scope.userFormTemplate = '/templates/partials/userForm.html'
	$scope.providers = [
		"facebook"
		"twitter"
		"google"
		"github"
		"stackexchange"
		"soundcloud"
		"youtube"
		"tumblr"
		"instagram"
		"linkedin"
		"deezer"
	]

	$scope.demoTwiConnect = () ->
		OAuth.initialize window.demoKey
		OAuth.popup 'twitter', (err, res) ->
			if err
				alert JSON.stringify err
				return
			res.get('/1.1/account/verify_credentials.json').done (data) ->
				alert 'Hello ' + data.name

	$scope.demoFbConnect = () ->
		OAuth.initialize window.demoKey
		OAuth.popup 'facebook', (err, res) ->
			if err
				alert JSON.stringify err
				return
			res.get('/me').done (data) ->
				alert 'Hello ' + data.name

	$scope.providerClick = (provider) ->
		$scope.selectedProvider = provider

  app.register.controller "IndexCtrl", [
    "$scope"
    IndexCtrl
  ]
  return