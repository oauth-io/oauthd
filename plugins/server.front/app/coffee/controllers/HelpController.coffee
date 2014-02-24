"use strict"
define ["app"], (app) ->
  HelpCtrl = (UserService, MenuService) ->
	MenuService.changed()
    return

  app.register.controller "HelpCtrl", [
    "$scope"
    HelpCtrl
  ]
  return
