"use strict"
define ["app"], (app) ->
	HelpCtrl = (UserService, MenuService) ->
		MenuService.changed()

	app.register.controller "HelpCtrl", [
		"$scope"
		HelpCtrl
	]
	return
