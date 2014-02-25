"use strict"
define [
	"app",
	"services/MenuService"
	], (app) ->
		LogoutCtrl = ($location, UserService, MenuService) ->
			UserService.logout()
			document.location.reload()

		app.register.controller "LogoutCtrl", [
			"$location"
			"UserService"
			"MenuService"
			LogoutCtrl
		]
		return
