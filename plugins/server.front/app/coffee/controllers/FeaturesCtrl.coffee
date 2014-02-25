"use strict"
define [
	"app",
	"services/UserService",
	"services/MenyService"
	], (app) ->
		FeaturesCtrl = (UserService, MenuService) ->
			MenuService.changed()

		app.register.controller "FeaturesCtrl", [
			"UserService"
			"MenuService"
			FeaturesCtrl
		]
		return
