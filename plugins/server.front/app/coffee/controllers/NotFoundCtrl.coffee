"use strict"
define [
	"app",
	"services/MenuService"
	], (app) ->
		NotFoundCtrl = ($scope, $routeParams, UserService, MenuService) ->
			MenuService.changed()
			$scope.errorGif = '/img/404/' + (Math.floor(Math.random() * 2) + 1) + '.gif'

		app.register.controller "NotFoundCtrl", [
			"$scope"
			"$routeParams"
			"UserService"
			"MenuService"
			NotFoundCtrl
		]
		return