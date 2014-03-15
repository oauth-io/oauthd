"use strict"
define [
	"services/UserService",
	"services/PaymentService",
	], () ->
		PurchaseCtrl = (UserService, $scope, $modalInstance, $rootScope, PaymentService) ->
			$scope.profile = type:'individual', country_code:'US' if not $scope.profile
			$scope.coupon = code:'', changed:false

			$scope.recompute = ->
				$scope.plan.total = $scope.plan.amount

				if $scope.profile.country_code == 'FR'
					$scope.plan.amount_vat = $scope.plan.amount * 20 / 100
					$scope.plan.total += $scope.plan.amount_vat

				if $scope.coupon.infos?.amount_off
					$scope.plan.amount_off = $scope.coupon.infos.amount_off / 100
					$scope.plan.total -= $scope.plan.amount_off
				else if $scope.coupon.infos?.percent_off
					$scope.plan.amount_off = $scope.plan.total * $scope.coupon.infos.percent_off / 100
					$scope.plan.total -= $scope.plan.amount_off
				else
					delete $scope.plan.amount_off

				$scope.plan.total = Math.round($scope.plan.total * 100) / 100

			$scope.confirmCoupon = ->
				coupon_code = $scope.coupon.code
				delete $scope.error
				delete $scope.coupon.infos
				delete $scope.coupon.registered
				$scope.recompute()
				PaymentService.coupon coupon:coupon_code, plan:$scope.plan.id, ((infos) ->
					mixpanel.track "coupon add"
					$scope.coupon.infos = infos.data
					$scope.coupon.registered = coupon_code
					$scope.coupon.changed = false
					$scope.recompute()
				), (error) ->
					$scope.error = error

			$scope.cancelSubscription = ->
				$modalInstance.close()

			$scope.confirmSubscription = ->
				if $scope.coupon.code and $scope.coupon.changed
					return $scope.confirmCoupon()
				delete $scope.error
				handler = $rootScope.stripeCheckout (token, args) ->
					PaymentService.subscribe {
						token: token
						plan: $scope.plan.id
						profile: $scope.profile
						coupon: $scope.coupon.registered
					}, (->
						$scope.purchaseModal.close()
						$rootScope.me.plan = $scope.plan
						$rootScope.me.plan.displayName = $rootScope.me.plan.name
						$rootScope.me.plan.name = $rootScope.me.plan.id
					), (error) -> $scope.error = error
				handler.open
					name: 'OAuth.io'
					email: $scope.user.mail
					description: $scope.plan.name + ' plan'
					amount: $scope.plan.total * 100

			$.getJSON '/data/countries.json', (json) ->
				$scope.countries = json
				$scope.$apply()
			UserService.me ((me)->
				$scope.user = me.data.profile
				$scope.profile.name = $scope.user.name
			), (error) ->
				console.log "error", error

			$scope.recompute()
		return [
			"UserService"
			"$scope"
			"$modalInstance"
			"$rootScope"
			"PaymentService"
			PurchaseCtrl
		]
