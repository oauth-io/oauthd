"use strict"
define [
	"app", 
	'services/UserService', 
	'services/MenuService'
	], (app) ->
		AboutCtrl = (UserService, MenuService) ->
			MenuService.changed()
		
		app.register.controller "AboutCtrl", [
			"UserService",
			"MenuService"
			AboutCtrl
		]
		return
