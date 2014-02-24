"use strict"
define ["app"], (app) ->
  app.register.controller "TestlapinController", [
    "$scope"
    ($scope) ->
      $scope.lapin = "Plop lapin"
  ]
  return
