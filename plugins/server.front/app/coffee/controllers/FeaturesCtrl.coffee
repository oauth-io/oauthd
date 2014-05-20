"use strict"
define [], () ->
	FeaturesCtrl = (UserService, MenuService, $scope, $anchorScroll) ->
		MenuService.changed()

		$anchorScroll()

		$('#try1').tryIt
			url: '/data/sampleFeature1.json'
			providers: ['facebook', 'twitter', 'google', 'github', 'linkedin']
			languages: ['js']
			tryIt: (lang, provider) =>
				OAuth.initialize window.demoKey
				OAuth.popup provider, (err, res) ->
					if err
						alert JSON.stringify err
						return
					alert res.access_token || res.oauth_token
					res.me().done (data) ->
						alert 'Hello ' + data.name
				mixpanel.track "feature demo 1"
				return false

		$('#try2').tryIt
			url: '/data/sampleFeature2.json'
			providers: ['facebook', 'twitter']
			languages: ['js']
			tryButton: false

	return [
		'UserService'
		'MenuService'
		'$scope'
		'$anchorScroll'
		FeaturesCtrl
	]
