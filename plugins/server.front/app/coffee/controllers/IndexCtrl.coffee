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

		$scope.tryIt = () ->
			OAuth.initialize window.demoKey
			OAuth.popup $scope.provider, (err, res) ->
				if err
					alert JSON.stringify err
					return
				res.me().done (data) ->
					console.log data
					alert 'Hello ' + data.name
			mixpanel.track "landing demo"
			return false

		$scope.provider = 'facebook'
		$scope.demoProvider = (provider) ->
			$("#demo-" + $scope.provider).attr('src', '/img/homepageicon/' + $scope.provider + 'black.png')
			$("#demo-" + provider).attr('src', '/img/homepageicon/' + provider + 'active.png')
			$('pre code').html $('pre code').html().replace(/facebook|twitter|github|google|linkedin/gi, provider)
			$scope.provider = provider

		$('pre code').each (i, e) -> hljs.highlightBlock e


	return [
		"$scope",
	    "$rootScope",
	    "$http",
	    "$location",
	    "UserService",
	    "MenuService" ,
		IndexCtrl
	]