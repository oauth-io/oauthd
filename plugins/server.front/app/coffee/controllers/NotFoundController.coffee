"use strict"
define ["app"], (app) ->
  NotFoundCtrl = ($scope, $routeParams, UserService, MenuService) ->
	MenuService.changed()
	$scope.errorGif = '/img/404/' + (Math.floor(Math.random() * 2) + 1) + '.gif'
    return

  app.register.controller "NotFoundCtrl", [
    "$scope"
    NotFoundCtrl
  ]
  return
