"use strict"
define [
	"app",
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
