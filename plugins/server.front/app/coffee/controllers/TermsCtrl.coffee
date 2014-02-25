"use strict"
define [
	"app",
	"services/MenuService"
	], (app) ->
		TermsCtrl = (UserService, MenuService) ->
			MenuService.changed()
		
		app.register.controller "TermsCtrl", [
			"UserService",
			"MenuService"
			TermsCtrl
		]
		return
