"use strict"
define ["app"], (app) ->
  TestlapinController = ($scope) ->
    $scope.lapin = "Plop lapin"
    return

  app.register.controller "TestlapinController", [
    "$scope"
    TestlapinController
  ]
  return
