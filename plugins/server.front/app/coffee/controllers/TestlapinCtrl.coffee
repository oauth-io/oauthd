"use strict"
define ["app"], (app) ->
  TestlapinController = ($scope) ->
    $scope.lapin = "Plop lapin"
    return

  app.register.controller "TestlapinCtrl", [
    "$scope"
    TestlapinController
  ]
  return
