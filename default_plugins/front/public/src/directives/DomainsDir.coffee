module.exports = (app) ->
	app.directive 'domains', ["$rootScope", ($rootScope) ->
		return {
			restrict: 'AE'
			templateUrl: '/templates/domains_chooser.html'
			replace: true
			scope: {
				control: '=',
				app: '='
			}
			link: ($scope, $element) ->
				selectize_elem = $($element[0]).selectize({
					delimiter: ' '
					persist: false
					create: (input) ->
						return {
							value: input,
							text: input
						}
				})

				$scope.selectize = selectize_elem[0].selectize
				$scope.control.getSelectize = () ->
					return $scope.selectize

				$scope.control.getDomains = () ->
					value = $scope.selectize.getValue()
					domains = value.split(' ')
					return domains
				if $scope.app?.domains?
					for k,v of $scope.app.domains
						$scope.selectize.addOption {
							text: v,
							value: v
						}
						$scope.selectize.addItem v

				add_listener = () ->
					$scope.selectize.on 'change', () ->
						value = $scope.selectize.getValue()
						domains = value.split(' ')
						$scope.app.domains = domains
						if $scope.control.change?
							$scope.control.change()

				remove_listener = () ->
					$scope.selectize.off 'change'

				$scope.control.refresh = (app) ->
					remove_listener()
					$scope.selectize.clear()
					$scope.app = app if app?
					for v in $scope.app.domains
						$scope.selectize.addOption {
							text: v,
							value: v
						}
						$scope.selectize.addItem v
					add_listener()
				add_listener()
				return
		}
	]