"use strict"
define [], () ->
	NotificationCtrl = ($scope, NotificationService) ->
		$scope.notifications = NotificationService.list()

    return [
    	"$scope"
    	"NotificationService",
    	NotificationCtrl
    ]