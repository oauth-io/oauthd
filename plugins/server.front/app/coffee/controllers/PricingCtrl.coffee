"use strict"
define [
	"controllers/PurchaseCtrl"
	"services/MenuService"
	"services/PaymentService"
], (PurchaseCtrl) ->
	PricingCtrl = ($scope, $rootScope, $modal, $location, MenuService, PaymentService) ->
		MenuService.changed()

		PaymentService.list (success) ->
			$scope.plans = success.data.offers.slice 1

		, (error) ->
			console.log error

		$scope.unsubscribe = (plan) ->
			if confirm("Are you sure to unsubscribe from " + plan.name + " ?")
				PaymentService.unsubscribe (success) ->
					$rootScope.me.plan =
						name: 'bootstrap'
						nbUsers: 1000
						nbApp: 2
						nbProvider: 2
				, (error) ->
					console.log error

		$scope.subscribe = (plan) ->
			$scope.plan = plan
			if not $rootScope.me
				$location.path '/signin'
				return
			mixpanel.track "purchase click"
			$scope.purchaseModal = $modal.open
				templateUrl: '/templates/partials/purchase-plan.html'
				controller: PurchaseCtrl
				scope: $scope
				resolve: ->
	return [
		"$scope"
		"$rootScope"
		"$modal"
		"$location"
		"MenuService"
		"PaymentService"
		PricingCtrl
	]
