"use strict"

###########################
# Landing page Controller #
###########################

define [], () ->
	IndexCtrl = ($scope, $rootScope, $http, $location, UserService, MenuService) ->
		MenuService.changed()
		# if UserService.isLogin()
		# 	$location.path '/key-manager'

		mixpanel.track_links "#landing-contribute", "landing contribute"
		mixpanel.track_links "#landing-see-demo", "landing see demo"
		mixpanel.track_links "#landing-learn-more", "landing learn more"
		mixpanel.track_links "#landing-try-it", "landing try it"
		mixpanel.track_links "#landing-try-it2", "landing try it2"
		$scope.demoTwiConnect = () ->
			OAuth.initialize window.demoKey
			OAuth.popup 'twitter', (err, res) ->
				if err
					alert JSON.stringify err
					return
				res.get('/1.1/account/verify_credentials.json').done (data) ->
					alert 'Hello ' + data.name
			mixpanel.track "landing demo tw"

		$scope.demoFbConnect = () ->
			OAuth.initialize window.demoKey
			OAuth.popup 'facebook', (err, res) ->
				if err
					alert JSON.stringify err
					return
				res.get('/me').done (data) ->
					alert 'Hello ' + data.name
			mixpanel.track "landing demo fb"

	return [
		"$scope",
	    "$rootScope",
	    "$http",
	    "$location",
	    "UserService",
	    "MenuService" ,
		IndexCtrl
	]