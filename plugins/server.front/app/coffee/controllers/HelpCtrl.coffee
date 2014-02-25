"use strict"
define [
	"app",
	"services/UserService",
	"services/MenuService"
	], (app) ->
		HelpCtrl = (UserService, MenuService) ->
			MenuService.changed()

		app.register.controller "HelpCtrl", [
			"UserService"
			"MenuService"
			HelpCtrl
		]
		return
