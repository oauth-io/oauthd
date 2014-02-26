"use strict"
define [], () ->
	EditorCtrl = ($scope, MenuService, ProviderService) ->
		MenuService.changed()

		$scope.providersDemo = [
			"facebook"
			"twitter"
			"github"
			"linkedin"
			"dropbox"
			"instagram"
			"google"
			"youtube"
			"foursquare"
			"soundcloud"
		]

		$scope.type = "oauth2"
		$scope.conf =
			"name": ""
			"url": ""
			"oauth2":
				"authorize": {}
				"access_token": {}
				"parameters":
					"client_id": "string"
					"client_secret": "string"
					"scope":
						"values": {
						}
						"cardinality": "*"
						"separator": ","

		$scope.addValue = (key, val) ->
			if not $scope.param.values
				$scope.param.values = {}

			$scope.param.values[key] = val
			delete $scope.value

		$scope.removeValue = (key) ->
			delete $scope.param.values[key]
			n = Object.size $scope.param.values
			if n == 0
				delete $scope.param.values

		$scope.addHref = (key, url) ->
			if not $scope.conf.href
				$scope.conf.href = {}

			$scope.conf.href[key] = url
			$scope.hrefkey = ""
			$scope.hrefurl = ""

		$scope.removeHref = (key) ->
			delete $scope.conf.href[key]
			n = Object.size $scope.conf.href
			if n == 0
				delete $scope.conf.href

		$scope.addParameter = () ->
			name = $scope.param.name
			if $scope.param.type == 'string'
				$scope.conf[$scope.type].parameters[name] = "string"
			else
				$scope.conf[$scope.type].parameters[name] =
					values: $scope.param.values
					cardinality: $scope.param.cardinality
					separator: $scope.param.separator
			$scope.param = {}
			$scope.paramForm = false

		$scope.removeParameter = (name) ->
			delete $scope.conf[$scope.type].parameters[name]

		$scope.loadConf = (provider) ->
			ProviderService.get provider, (data) =>
				$scope.conf = data.data
				if data.data.oauth2?
					$scope.type = "oauth2"
				else
					$scope.type = "oauth1"

		$scope.getParamType = (key) ->
			if $scope.conf[$scope.type].parameters[key] == "string" || $scope.conf[$scope.type].parameters[key].type == "string"
				return "string"
			else
				return "object"


		$scope.removeQuery = (key, type) ->
			delete $scope.conf[$scope.type][type].query[key]
			n = Object.size $scope.conf[$scope.type][type].query
			if n == 0
				delete $scope.conf[$scope.type][type]['query']

		$scope.addQuery = (type) ->
			if type == 'authorize'
				key = $scope.key2
				val = $scope.val2
				$scope.key2 = ''
				$scope.val2 = ''
			else if type == 'request_token'
				key = $scope.key1
				val = $scope.val1
				$scope.key1 = ''
				$scope.val1 = ''
			else if type == 'access_token'
				key = $scope.key3
				val = $scope.val3
				$scope.key3 = ''
				$scope.val3 = ''

			# alert type + ' ' + $scope.type
			if not $scope.conf[$scope.type][type]? or $scope.conf[$scope.type][type] is ""
				$scope.conf[$scope.type][type] = {query:{}}
			if not $scope.conf[$scope.type][type].query?
				$scope.conf[$scope.type][type].query = {}

			$scope.conf[$scope.type][type].query[key] = val

		$scope.oauthType = () ->
			if $scope.type is "oauth1"
				type2 = "oauth2"
			else
				type2 = "oauth1"

			$scope.conf[$scope.type] = $scope.conf[type2]
			delete $scope.conf[type2]
			delete $scope.conf[$scope.type].request_token if $scope.type == 'oauth2'
			$scope.conf[$scope.type].request_token = "" if $scope.type == 'oauth1'
		
	return [
		'$scope', 
		'MenuService', 
		'ProviderService',
		EditorCtrl
	]
