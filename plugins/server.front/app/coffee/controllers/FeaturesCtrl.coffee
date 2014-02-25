"use strict"
define [
	"app"
	], (app) ->
		FeaturesCtrl = (UserService, MenuService) ->
			MenuService.changed()

		app.register.controller "FeaturesCtrl", [
			"UserService"
			"MenuService"
			FeaturesCtrl
		]
		return
