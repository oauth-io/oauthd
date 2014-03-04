"use strict"
define [
	"services/MenuService"
	], () ->
		TermsCtrl = (UserService, MenuService) ->
			MenuService.changed()
		
		return [
			"UserService",
			"MenuService",
			TermsCtrl
		]