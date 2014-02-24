"use strict"
define ["app"], (app) ->
  ImprintCtrl = (MenuService) ->
	MenuService.changed()

  app.register.controller "ImprintCtrl", [
    "$scope"
    ImprintCtrl
  ]
  return
