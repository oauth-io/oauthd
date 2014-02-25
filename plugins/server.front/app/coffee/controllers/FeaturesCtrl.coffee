"use strict"
define [
	"app",
	"services/UserService",
	"services/MenuService"
	], (app) ->
		FeaturesCtrl = (UserService, MenuService) ->
			MenuService.changed()

		app.register.controller "FeaturesCtrl", [
			"UserService"
			"MenuService"
			FeaturesCtrl
		]
		return
