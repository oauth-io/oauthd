"use strict"
define [
	"app",
	"services/MenuService"
	], (app) ->
		ImprintCtrl = (MenuService) ->
			MenuService.changed()
			
		app.register.controller "ImprintCtrl", [
			"MenuService"
			ImprintCtrl
		]
		return
