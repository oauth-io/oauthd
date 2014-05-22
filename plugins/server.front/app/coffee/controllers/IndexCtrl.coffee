"use strict"

###########################
# Landing page Controller #
###########################

define [], () ->
	IndexCtrl = ($scope, $rootScope, $http, $location, UserService, MenuService) ->
		MenuService.changed false
		# if UserService.isLogin()
		# 	$location.path '/key-manager'

		mixpanel.track_links "#landing-signup", "landing signup"
		mixpanel.track_links "#landing-learn-more", "landing learn more"

		$('.try-it').tryIt
			url: '/data/sampleLandingPage.json'
			providers: ['facebook', 'twitter', 'google', 'github', 'linkedin']
			languages: ['js']
			tryIt: (lang, provider) =>
				OAuth.initialize window.demoKey
				if provider == 'facebook'
					OAuth.popup provider, {authorize:{display:'popup'}}, (err, res) ->
						if err
							# alert JSON.stringify err
							return
						res.me().done (data) ->
							alert 'Hello ' + data.name
				else
					OAuth.popup provider, (err, res) ->
						if err
							# alert JSON.stringify err
							return
						res.me().done (data) ->
							alert 'Hello ' + data.name
				mixpanel.track "landing demo"
				return false

	return [
		"$scope",
	    "$rootScope",
	    "$http",
	    "$location",
	    "UserService",
	    "MenuService" ,
		IndexCtrl
	]