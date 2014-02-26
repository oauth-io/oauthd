"use strict"
define [], () ->
	LogoutCtrl = ($location, UserService, MenuService) ->
		UserService.logout()
		document.location.reload()

	return [
		"$location",
		"UserService",
		"MenuService",
		LogoutCtrl
	]