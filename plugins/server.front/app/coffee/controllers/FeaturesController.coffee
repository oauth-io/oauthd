"use strict"
define ["app"], (app) ->
  FeaturesCtrl = (UserService, MenuService) ->
	MenuService.changed()
	return

  app.register.controller "FeaturesCtrl", [
    "$scope"
    FeaturesCtrl
  ]
  return
