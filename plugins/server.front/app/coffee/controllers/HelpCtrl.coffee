"use strict"
define [
	"app"
	], (app) ->
		HelpCtrl = (UserService, MenuService) ->
			MenuService.changed()

		app.register.controller "HelpCtrl", [
			"UserService"
			"MenuService"
			HelpCtrl
		]
		return
