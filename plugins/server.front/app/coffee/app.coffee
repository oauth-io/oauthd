"use strict"
define ["services/routeResolver"], ->
  app = angular.module("oauth", [
    "routeResolverServices"
    "ui.bootstrap"
    "ngDragDrop"
    "ui.select2"
    "ngCookies"
  ])
  app.config [
    "$routeProvider"
    "$locationProvider"
    "routeResolverProvider"
    "$controllerProvider"
    "$compileProvider"
    "$filterProvider"
    "$provide"
    ($routeProvider, $locationProvider, routeResolverProvider, $controllerProvider, $compileProvider, $filterProvider, $provide) ->
      app.register =
        controller: $controllerProvider.register
        directive: $compileProvider.directive
        filter: $filterProvider.register
        factory: $provide.factory
        service: $provide.service

      route = routeResolverProvider.route
      $routeProvider.when("/testlapin", route.resolve("Testlapin"))
  ]
  app
