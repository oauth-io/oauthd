"use strict"
define ["app"], (app) ->
  TermsCtrl = (UserService, MenuService) ->
	MenuService.changed()
    return

  app.register.controller "TermsCtrl", [
    "$scope"
    TermsCtrl
  ]
  return
