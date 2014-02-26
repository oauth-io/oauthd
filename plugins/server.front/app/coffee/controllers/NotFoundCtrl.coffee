"use strict"
define [], () ->
	NotFoundCtrl = ($scope, $routeParams, UserService, MenuService) ->
		MenuService.changed()
		$scope.errorGif = '/img/404/' + (Math.floor(Math.random() * 2) + 1) + '.gif'

	return [
		"$scope",
		"$routeParams",
		"UserService",
		"MenuService",
		NotFoundCtrl
	]