"use strict"
define [
	"app",
	"services/NotificationService"
	], (app) ->
	    NotificationCtrl = ($scope, NotificationService) ->
	        $scope.notifications = NotificationService.list()
	    app.register.controller "NotificationCtrl", [
	        "$scope"
	        "NotificationService"
	        NotificationCtrl
	    ]
	    return
