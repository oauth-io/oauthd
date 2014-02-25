"use strict"
define [
	"app",
	"services/UserService",
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
