"use strict"
define [
	"app"
	], (app) ->
	    NotificationCtrl = ($scope, NotificationService) ->
	        $scope.notifications = NotificationService.list()
	    app.register.controller "NotificationCtrl", [
	        "$scope"
	        "NotificationService"
	        NotificationCtrl
	    ]
	    return
