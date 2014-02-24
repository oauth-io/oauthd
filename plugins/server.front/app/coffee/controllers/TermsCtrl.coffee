"use strict"
define ["app"], (app) ->
	TermsCtrl = (UserService, MenuService) ->
		MenuService.changed()
	
	app.register.controller "TermsCtrl", [
    "UserService",
    "MenuService"
    TermsCtrl
  ]
  return
