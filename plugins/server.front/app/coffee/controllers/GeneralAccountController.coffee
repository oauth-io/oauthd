"use strict"
define ["app"], (app) ->
  generalAccountCtrl = ($rootScope, $scope, $timeout, UserService) ->
	connectionCtx = document.getElementById('connectionChart').getContext '2d'
	appsCtx = document.getElementById('appsChart').getContext '2d'
	providersCtx = document.getElementById('providersChart').getContext '2d'

	drawChart = ->
		getColor = (ratio)->
			if ratio > 0.66
				return '#F7464A'
			else if ratio > 0.33
				return '#ffb554'
			else
				return '#3ebebd'

		connectionData = [
			value: $rootScope.me.totalUsers
			color: getColor $rootScope.me.totalUsers / $rootScope.me.plan.nbUsers
		,
			value: $rootScope.me.plan.nbUsers - $rootScope.me.totalUsers
			color: '#EEEEEE'
		]
		connectionData[1].value = 0  if connectionData[1].value < 0
		connectionChart = new Chart(connectionCtx).Doughnut(connectionData)

		if $rootScope.me.plan.nbApp != 'unlimited'
			appsData = [
				value: $rootScope.me.apps.length
				color: getColor $rootScope.me.apps.length / $rootScope.me.plan.nbApp
			,
				value: $rootScope.me.plan.nbApp - $rootScope.me.apps.length
				color: '#EEEEEE'
			]
			appsData[1].value = 0  if appsData[1].value < 0
			appsChart = new Chart(appsCtx).Doughnut(appsData)

		if $rootScope.me.plan.nbProvider != 'unlimited'
			providersData = [
				value: $rootScope.me.keysets.length
				color: getColor $rootScope.me.keysets.length / $rootScope.me.plan.nbProvider
			,
				value: $rootScope.me.plan.nbProvider - $rootScope.me.keysets.length
				color: '#EEEEEE'
			]
			providersData[1].value = 0  if providersData[1].value < 0
			providersChart = new Chart(providersCtx).Doughnut(providersData)

	$rootScope.$watch 'loading', (newval, oldval) -> drawChart() if newval == false
	return
	
  app.register.controller "generalAccountCtrl", [
    "$scope"
    generalAccountCtrl
  ]
  return
