module.exports = (app) ->
	app.directive 'keyseteditor', ['$rootScope', 'ProviderService', 'KeysetService', ($rootScope, ProviderService, KeysetService) ->
		return {
			restrict: 'AE'
			template: '<div></div>'
			replace: true
			scope: {
				provider: '=',
				control: '='
			}
			link: ($scope, $element) ->
				$elt = $($element[0])
				$scope.control = $scope.control


				update = () ->
					
					ProviderService.get $scope.provider
						.then (config) ->

							$scope.available_parameters = config?.oauth2?.parameters || config?.oauth1?.parameters || config?.parameters
							$elt.html('')
							for k of $scope.available_parameters
								param_config = $scope.available_parameters[k]
								

								field = $(document.createElement('div'))
								$elt.append field
								field.append('<div><strong>' + k + '</strong></div>')
								if $scope.available_parameters[k]?.values?
									values = []
									for kk of $scope.available_parameters[k].values
										vv = $scope.available_parameters[k].values[kk]
										values.push {
											name: kk,
											value: vv
										}
									if param_config.cardinality? && param_config.cardinality == '*'
										# Create a selectize input
										input = $(document.createElement('input'))
										field.append input
										input.val($scope.keyset?.parameters?[k])
										selectize = input.selectize({
											delimiter: ' '
											persist: false
											valueField: 'name'
											labelField: 'value'
											searchField: ['name', 'value']
											options: values
											render: {
												item: (item, escape) ->
													return '<div><span class="name">' + item.name + '</span></div>'
												option: (item, escape) ->
													label = item.name
													desc = item.value
													return '<div><div class="scope_name">' + escape(label) + '</div><div class="scope_desc">' + escape(desc) + '</div></div>'
												create: (input) ->
													return {
														value: input,
														text: input
													}
											}
										})
										do (selectize, k) ->
											selectize = selectize[0].selectize

											selectize.on 'change', () ->
												$scope.keyset.parameters[k] = this.getValue()
												$scope.control.change()
												

									if param_config.cardinality? && param_config.cardinality == '1'
										# Create a selectize select
										input = $(document.createElement('select'))
										field.append input
										selectize = input.selectize({
											delimiter: ' '
											persist: false
											valueField: 'name'
											labelField: 'value'
											searchField: ['name', 'value']
											options: values
											render: {
												item: (item, escape) ->
													return '<div><span class="name">' + item.name + '</span></div>'
												option: (item, escape) ->
													label = item.name
													desc = item.value
													return '<div><div class="scope_name">' + escape(label) + '</div><div class="scope_desc">' + escape(desc) + '</div></div>'
												create: (input) ->
													return {
														value: input,
														text: input
													}
											}
										})
										do (selectize, k) ->
											selectize = selectize[0].selectize
											selectize.addItem($scope.keyset?.parameters?[k])
											selectize.on 'change', () ->
												$scope.keyset.parameters[k] = this.getValue()
												$scope.control.change()
												
								else
									input = $(document.createElement('input'))
									field.append input
									input.addClass 'form-control'
									input.val($scope.keyset?.parameters?[k])
									do (k, input) ->
										input.change () ->
											$scope.keyset.parameters[k] = input.val()
											$scope.control.change()


						.fail (e) ->
							console.log e

				if $scope.provider?
					update()

				$scope.$watch 'provider', () ->
					if $scope.app? && $scope.provider?
						update()

				$scope.control.getKeyset = () ->
					return $scope.keyset

				$scope.control.setKeyset = (keyset) ->
					$scope.keyset = keyset
					update()
				

				

		}
	]