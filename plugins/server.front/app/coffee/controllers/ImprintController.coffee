"use strict"
define ["app"], (app) ->
  ImprintCtrl = (MenuService) ->
	MenuService.changed()
    return

  app.register.controller "ImprintCtrl", [
    "$scope"
    ImprintCtrl
  ]
  return
