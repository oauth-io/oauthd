"use strict"
define ["app"], (app) ->
  NotificationCtrl = ($scope, NotificationService) ->
	$scope.notifications = NotificationService.list()
	return
	
  app.register.controller "NotificationCtrl", [
    "$scope"
    NotificationCtrl
  ]
  return
