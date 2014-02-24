"use strict"
define ["app"], (app) ->
  FeaturesCtrl = (UserService, MenuService) ->
	MenuService.changed()

  app.register.controller "FeaturesCtrl", [
    "$scope"
    FeaturesCtrl
  ]
  return
