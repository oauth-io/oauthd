"use strict"
define ["app"], (app) ->
  AboutCtrl = (UserService, MenuService) ->
	MenuService.changed()
    return

  app.register.controller "AboutCtrl", [
    "$scope"
    AboutCtrl
  ]
  return
