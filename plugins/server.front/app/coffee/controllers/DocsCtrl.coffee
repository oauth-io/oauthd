"use strict"
define [
	"app",
	"services/UserService",
	"services/MenyService"
	], (app) ->
		DocsCtrl = ($scope, UserService, MenuService, $routeParams, $location) ->
			MenuService.changed()
			if not $routeParams.page
				$scope.page = 'getting-started'
				$scope.docTemplate = "/templates/partials/docs/getting-started.html"
				return

			pages = ['getting-started','tutorial','api','faq','oauthd','security','oauthio_api', 'mobiles']
			if pages.indexOf($routeParams.page) >= 0
				$scope.page = $routeParams.page
				$scope.docTemplate = "/templates/partials/docs/" + $routeParams.page + ".html"
			else
				$location.path '/404'
			
		app.register.controller "DocsCtrl", [
			"$scope"
			"UserService"
			"MenuService"
			"$routeParams"
			"$location"
			DocsCtrl
		]
		return
