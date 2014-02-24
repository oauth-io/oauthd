"use strict"
define ["app"], (app) ->
  LogoutCtrl = ($location, UserService, MenuService) ->
	UserService.logout()
	document.location.reload()

  app.register.controller "LogoutCtrl", [
    "$scope"
    LogoutCtrl
  ]
  return
