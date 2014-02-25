"use strict"
define [
	"app",
	"services/UserService",
	"services/MenuService",
	"services/PricingService",
	"services/CartService"
	], (app) ->
		PricingCtrl = ($scope, $location, MenuService, UserService, PricingService, CartService) ->

			MenuService.changed()

			$scope.current_plan = null
			$scope.devShow = window.devShow

			PricingService.list (success) ->
				$scope.current_plan = success.data.current_plan
				$scope.plans = success.data.offers
			, (error) ->
				console.log error

			if $location.path() == '/pricing/unsubscribe'
				CartService.get (success) ->
					$scope.cart = success.data
				, (error) ->
					console.log error

			$scope.unsubscribe_confirm = (plan) ->

				$("#unsubscribe_#{plan.id}").hide()

				$("#loader_#{plan.id}").fadeIn 1000, ->
					CartService.add plan, (success) ->
						$location.path "/pricing/unsubscribe" if success
					, (error) ->
						console.log error

			$scope.unsubscribe = ->

				$('#bt-unsubscribe').hide 0, ->
					$('#waiting-unsubscribe').fadeIn(1000)

				PricingService.unsubscribe (success) ->
					$scope.current_plan = null
					$location.path "/pricing" if success
				, (error) ->
					console.log error

			$scope.subscribe = (plan) ->

				$("#purchase_#{plan.id}").hide()

				$("#loader_#{plan.id}").fadeIn 1000, ->

					CartService.add plan, (success) ->
						$location.path "/payment/customer" if success
					, (error) ->
						console.log error

		app.register.controller "PricingCtrl", [
			"$scope"
			"$location"
			"MenuService"
			"UserService"
			"PricingService"
			"CartService"
			PricingCtrl
		]
		return
