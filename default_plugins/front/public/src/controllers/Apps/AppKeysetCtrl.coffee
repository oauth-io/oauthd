module.exports = (app) ->
	app.controller('AppKeysetCtrl', ['$state', '$scope', '$rootScope', '$location', 'UserService', '$stateParams', 'AppService', 'ProviderService', 'KeysetService',
		($state, $scope, $rootScope, $location, UserService, $stateParams, AppService, ProviderService, KeysetService) ->
			AppService.get $stateParams.key
				.then (app) ->
					$scope.app = app
					$scope.setApp app
					$scope.setProvider $stateParams.provider
					$scope.$apply()
				.fail (e) ->
					console.log e


			KeysetService.get $stateParams.key, $stateParams.provider
				.then (keyset) ->
					$scope.keyset = keyset
					$scope.apply()
				.fail (e) ->
					$scope.keyset = {}

			ProviderService.get $stateParams.provider
				.then (config) ->
					$scope.available_parameters = config.oauth2?.parameters || config.oauth1?.parameters || config.parameters
					

					console.log $scope.available_parameters.client_secret
					$scope.$apply()

					for k of $scope.available_parameters
						if $scope.available_parameters[k]?.values?
							values = []
							for kk of $scope.available_parameters[k].values
								vv = $scope.available_parameters[k].values[kk]
								values.push {
									name: kk,
									value: vv
								}

							$scope.selectize_inputs[k] = $('.keyset').find('.parameter_input_' + k).selectize({
									delimiter: ' '
									persist: false
									valueField: 'name',
									labelField: 'value',
									searchField: ['name', 'value'],
									options: values,
									render: {		
										item: (item, escape) ->
											return '<div>' + '<span class="name">' + item.name + '</span>' + '</div>';
										,
										option: (item, escape) ->
											label = item.name
											desc =  item.value
											return '<div>' +
												'<div class="scope_name">' + escape(label) + '</div>' +
												'<div class="scope_desc">' + escape(desc) + '</div>' +
											'</div>';
										
									},
									create: (input) ->
										return {
											value: input,
											text: input
										}
								})

	])	