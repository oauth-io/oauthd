"use strict"
define ["app"], (app) ->
	PaymentCtrl = ($scope, $rootScope, $location, $route, $routeParams, UserService, PaymentService, PricingService, MenuService, CartService) ->
		MenuService.changed()

		if not UserService.isLogin()
			$location.path '/signin'
			return


		$scope.processingOrder = false

		$scope.countries = [{code : "US", name : "United States"},
							{code : "AL", name : "Albania"},
							{code : "DZ", name : "Algeria"},
							{code : "AD", name : "Andorra"},
							{code : "AO", name : "Angola"},
							{code : "AI", name : "Anguilla"},
							{code : "AG", name : "Antigua and Barbuda"},
							{code : "AM", name : "Armenia"},
							{code : "AZ", name : "Azerbaijan Republic"},
							{code : "AD", name : "Andorra"},
							{code : "AI", name : "Anguilla"},
							{code : "AR", name : "Argentina"},
							{code : "AW", name : "Aruba"},
							{code : "AU", name : "Australia"},
							{code : "AT", name : "Austria"},
							{code : "BS", name : "Bahamas"},
							{code : "BH", name : "Bahrain"},
							{code : "BB", name : "Barbados"},
							{code : "BE", name : "Belgium"},
							{code : "BZ", name : "Belize"},
							{code : "BJ", name : "Benin"},
							{code : "BM", name : "Bermuda"},
							{code : "BT", name : "Bhutan"},
							{code : "BO", name : "Bolivia"},
							{code : "BA", name : "Bosnia and Herzegovina"},
							{code : "BW", name : "Botswana"},
							{code : "BR", name : "Brazil"},
							{code : "VG", name : "British Virgin Islands"},
							{code : "BN", name : "Brunei"},
							{code : "BG", name : "Bulgaria"},
							{code : "BF", name : "Burkina Faso"},
							{code : "BI", name : "Burundi"},
							{code : "KH", name : "Cambodia"},
							{code : "CA", name : "Canada"},
							{code : "CV", name : "Cape Verde"},
							{code : "KY", name : "Cayman Islands"},
							{code : "TD", name : "Chad"},
							{code : "CL", name : "Chile"},
							{code : "C2", name : "China"},
							{code : "CR", name : "Costa Rica"},
							{code : "CO", name : "Colombia"},
							{code : "KM", name : "Comoros"},
							{code : "CK", name : "Cook Islands"},
							{code : "HR", name : "Croatia"},
							{code : "CY", name : "Cyprus"},
							{code : "CZ", name : "Czech Republic"},
							{code : "DK", name : "Denmark"},
							{code : "CD", name : "Democratic Republic of the Congo"},
							{code : "DJ", name : "Djibouti"},
							{code : "DM", name : "Dominica"},
							{code : "DO", name : "Dominican Republic"},
							{code : "EC", name : "Ecuador"},
							{code : "SV", name : "El Salvador"},
							{code : "ER", name : "Eritrea"},
							{code : "EE", name : "Estonia"},
							{code : "ET", name : "Ethiopia"},
							{code : "FK", name : "Falkland Islands"},
							{code : "FO", name : "Faroe Islands"},
							{code : "FM", name : "Federated States of Micronesia"},
							{code : "FJ", name : "Fiji"},
							{code : "FI", name : "Finland"},
							{code : "FR", name : "France"},
							{code : "GF", name : "French Guiana"},
							{code : "PF", name : "French Polynesia"},
							{code : "GA", name : "Gabon Republic"},
							{code : "GM", name : "Gambia"},
							{code : "DE", name : "Germany"},
							{code : "GI", name : "Gibraltar"},
							{code : "GR", name : "Greece"},
							{code : "GL", name : "Greenland"},
							{code : "GD", name : "Grenada"},
							{code : "GP", name : "Guadeloupe"},
							{code : "GT", name : "Guatemala"},
							{code : "GN", name : "Guinea"},
							{code : "GW", name : "Guinea Bissau"},
							{code : "GY", name : "Guyana"},
							{code : "HN", name : "Honduras"},
							{code : "HK", name : "Hong Kong"},
							{code : "HU", name : "Hungary"},
							{code : "IS", name : "Iceland"},
							{code : "IN", name : "India"},
							{code : "ID", name : "Indonesia"},
							{code : "IE", name : "Ireland"},
							{code : "IL", name : "Israel"},
							{code : "IT", name : "Italy"},
							{code : "JM", name : "Jamaica"},
							{code : "JP", name : "Japan"},
							{code : "JO", name : "Jordan"},
							{code : "KZ", name : "Kazakhstan"},
							{code : "KE", name : "Kenya"},
							{code : "KI", name : "Kiribati"},
							{code : "KW", name : "Kuwait"},
							{code : "KG", name : "Kyrgyzstan"},
							{code : "LA", name : "Laos"},
							{code : "LV", name : "Latvia"},
							{code : "LS", name : "Lesotho"},
							{code : "LI", name : "Liechtenstein"},
							{code : "LT", name : "Lithuania"},
							{code : "LU", name : "Luxembourg"},
							{code : "MG", name : "Madagascar"},
							{code : "MW", name : "Malawi"},
							{code : "MY", name : "Malaysia"},
							{code : "MV", name : "Maldives"},
							{code : "ML", name : "Mali"},
							{code : "MT", name : "Malta"},
							{code : "MH", name : "Marshall Islands"},
							{code : "MQ", name : "Martinique"},
							{code : "MR", name : "Mauritania"},
							{code : "MU", name : "Mauritius"},
							{code : "YT", name : "Mayotte"},
							{code : "MX", name : "Mexico"},
							{code : "MN", name : "Mongolia"},
							{code : "MS", name : "Montserrat"},
							{code : "MA", name : "Moroccoupdate"},
							{code : "MZ", name : "Mozambique"},
							{code : "NA", name : "Namibia"},
							{code : "NR", name : "Nauru"},
							{code : "NP", name : "Nepal"},
							{code : "NL", name : "Netherlands"},
							{code : "AN", name : "Netherlands Antilles"},
							{code : "NC", name : "New Caledonia"},
							{code : "NZ", name : "New Zealand"},
							{code : "NI", name : "Nicaragua"},
							{code : "NE", name : "Niger"},
							{code : "NU", name : "Niue"},
							{code : "NF", name : "Norfolk Island"},
							{code : "NO", name : "Norway"},
							{code : "OM", name : "Oman"},
							{code : "PW", name : "Palau"},
							{code : "PA", name : "Panama"},
							{code : "PG", name : "Papua New Guinea"},
							{code : "PE", name : "Peru"},
							{code : "PH", name : "Philippines"},
							{code : "PN", name : "Pitcairn Islands"},
							{code : "PL", name : "Poland"},
							{code : "PT", name : "Portugal"},
							{code : "QA", name : "Qatar"},
							{code : "CG", name : "Republic of the Congo"},
							{code : "RE", name : "Reunion"},
							{code : "RO", name : "Romania"},
							{code : "RU", name : "Russia"},
							{code : "RW", name : "Rwanda"},
							{code : "VC", name : "Saint Vincent and the Grenadines"},
							{code : "WS", name : "Samoa"},
							{code : "SM", name : "San Marino"},
							{code : "ST", name : "São Tomé and Príncipe"},
							{code : "SA", name : "Saudi Arabia"},
							{code : "SN", name : "Senegal"},
							{code : "SC", name : "Seychelles"},
							{code : "SL", name : "Sierra Leone"},
							{code : "SG", name : "Singapore"},
							{code : "SI", name : "Slovenia"},
							{code : "SB", name : "Solomon Islands"},
							{code : "SO", name : "Somalia"},
							{code : "ZA", name : "South Africa"},
							{code : "KR", name : "South Korea"},
							{code : "ES", name : "Spain"},
							{code : "LK", name : "Sri Lanka"},
							{code : "SH", name : "St. Helena"},
							{code : "KN", name : "St. Kitts and Nevis"},
							{code : "LC", name : "St. Lucia"},
							{code : "PM", name : "St. Pierre and Miquelon"},
							{code : "SR", name : "Suriname"},
							{code : "SJ", name : "Svalbard and Jan Mayen Islands"},
							{code : "SZ", name : "Swaziland"},
							{code : "SE", name : "Sweden"},
							{code : "CH", name : "Switzerland"},
							{code : "TJ", name : "Tajikistan"},
							{code : "TW", name : "Taiwan"},
							{code : "TZ", name : "Tanzania"},
							{code : "TH", name : "Thailand"},
							{code : "TG", name : "Togo"},
							{code : "TO", name : "Tonga"},
							{code : "TT", name : "Trinidad and Tobago"},
							{code : "TN", name : "Tunisia"},
							{code : "TR", name : "Turkey"},
							{code : "TM", name : "Turkmenistan"},
							{code : "TC", name : "Turks and Caicos Islands"},
							{code : "TV", name : "Tuvalu"},
							{code : "UG", name : "Uganda"},
							{code : "UA", name : "Ukraine"},
							{code : "AE", name : "United Arab Emirates"},
							{code : "GB", name : "United Kingdom"},
							{code : "US", name : "United States"},
							{code : "UY", name : "Uruguay"},
							{code : "VU", name : "Vanuatu"},
							{code : "VA", name : "Vatican City State"},
							{code : "VE", name : "Venezuela"},
							{code : "VN", name : "Vietnam"},
							{code : "WF", name : "Wallis and Futuna Islands"},
							{code : "YE", name : "Yemen"},
							{code : "ZM", name : "Zambia"}]

		$("#vatNumber").hide()
		$("#State").hide()
		$("#BillingvatNumber").hide()
		$("#BillingState").hide()


		# trop long
		UserService.me (success) ->
			$scope.profile = success.data.profile
			$scope.billing = success.data.billing
			$scope.profile.addr_one = $scope.profile.addr_one || ""
			$scope.profile.addr_second = $scope.profile.addr_second || ""
			$scope.profile.zipcode = $scope.profile.zipcode || ""
			$scope.profile.state = $scope.profile.state || ""
			$scope.profile.city = $scope.profile.city || ""
			$scope.profile.phone = $scope.profile.phone || ""
			$scope.profile.use_profile_for_billing = true
			$scope.handleBillingAddress()
		, (error) ->
			console.log error


		if $location.path() == '/payment/customer' or $location.path() == '/payment/confirm'
			CartService.get (success) ->
				$scope.cart = success.data
			, (error) ->
				console.log error

			PaymentService.getCurrentSubscription (success) ->
				$scope.subscription = success.data

		cc = ["AT","AD","AM","AZ","BA","BE","BG","DE","CY","HR","CZ","DK","EE","FI","FR","GR","HU","IS","IR","IT","KZ","LV","LI","LT","LU","MT","NL","NO","PL","PT","RO","SI","ES","TR","SE","GB"]

		$scope.updateCountry = ->
			$("#vatNumber").hide()
			$("#State").hide()
			if cc.findIndex($scope.profile.country_code) isnt -1
				$("#vatNumber").show()

			if $scope.profile.country_code is "US"
				$("#State").show()

		$scope.billingUpdateCountry = ->
			$("#BillingvatNumber").hide()
			$("#BillingState").hide()
			if cc.findIndex($scope.profile.country_code) isnt -1
				$("#BillingvatNumber").show()

			if $scope.billing.country_code is "US"
				$("#BillingState").show()

		$scope.handleBillingAddress = ->
			if not $scope.profile.use_profile_for_billing
				$scope.billing =
					type: 'individual'
			else
				$scope.billing = $scope.profile
				$scope.billing.use_profile_for_billing = true


		$scope.process_billing = ->
			fields =
				"#profile_company": "error name of the company missing"
				"#profile_vat_number": "error VAT number missing"
				"#profile_name": "error first name and last name missing"
				"#profile_mail": "error mail missing"
				"#profile_addr_one": "error address missing"
				"#profile_country_code": "error country missing"
				"#profile_zipcode": "error zipcode missing"
				"#profile_city": "error city missing"
				"#profile_state": "error state missing"
				"#billing_company": "error name of the company missing"
				"#billing_vat_number": "error VAT number missing"
				"#billing_name": "error first name and last name missing"
				"#billing_addr_one": "error address missing"
				"#billing_country_code": "error country missing"
				"#billing_zipcode": "error zipcode missing"
				"#billing_city": "error city missing"
				"#billing_state": "error state missing"


			for i of fields
				if $(i).is(":visible") and $(i).val() is ""
					console.log "error"
					$scope.error =
						state: true
						message: fields[i]
					$scope.processingOrder = false
					return null
			$scope.processingOrder = true

			if $scope.profile.use_profile_for_billing
				$scope.billing = $scope.profile

			for country in $scope.countries
				if $scope.billing.country_code == country.code
					$scope.billing.country = country.name
					break # ?

			UserService.createBilling $scope.profile, $scope.billing, (success) ->
				$location.path "/payment/confirm"
			, (error) ->
				$scope.error =
					state : true
					message : error.message

				$scope.processingOrder = false

		$scope.process_order = ->
			$scope.processingOrder = true
			$scope.error =
					state: false
					message : ''

			fields = {
				"#card-number": "error card number missing"
				"#card-expiry-month": "error expiration date missing (month)"
				"#card-expiry-year": "error expiration date missing (year)"
				"#card-cvc": "error card cvc missing"
			}

			for i of fields
				if $(i).val() is ""
					console.log 'Error'
					$scope.error =
						state: true
						message: fields[i]
					$scope.processingOrder = false
					return null

			# process order
			params_for_token = checkoutParamsForToken()
			paymill_data =
				currency: 'USD'
				amount: $scope.cart.total * 100
				token: ''
				offer: $scope.cart.plan_id

			offer_name = $scope.cart.plan_name

			if params_for_token?
				paymill.createToken params_for_token, (error, result) ->
					if not result?.token and error?.message
						$scope.error =
							state: true
							message: "Paymill Error: " + error.message.replace /\+/g, " "
						$scope.processingOrder = false
						$scope.$apply()
						_cio.track "paymill.error", message:error.message.replace(/\+/g, " ")
						return
					paymill_data.token = result.token
					PaymentService.process paymill_data, (success) ->
						$rootScope.subscription = success.data[2].data.id
						$location.path "/payment/#{offer_name}/success"
					, (error) ->
						$scope.error =
							state: true
							message : error.message

						$scope.processingOrder = false

		checkoutParamsForToken = ->
			if !paymill.validateCardNumber($('.card-number').val())
				$scope.error =
					state: true
					message : 'Invalid card number'
				$scope.processingOrder = false
				return null

			if !paymill.validateExpiry($('.card-expiry-month').val(), $('.card-expiry-year').val())
				$scope.error =
					state: true
					message : 'Invalid card expiry date'
				$scope.processingOrder = false
				return null

			if !paymill.validateCvc($('.card-cvc').val(), $('.card-number').val())
				$scope.error =
					state: true
					message : 'Invalid card CVC'
				$scope.processingOrder = false
				return null

			# if $('.card-holdername').val() == ''
			# 	$scope.error =
			# 		state: true
			# 		message : 'Invalid card holdername'

			# 	return null

			params =
				currency: 'USD'
				number: $('.card-number').val()
				exp_month: $('.card-expiry-month').val()
				exp_year: $('.card-expiry-year').val()
				cvc: $('.card-cvc').val()
				amount: $scope.cart.total * 100

			return params
	app.register.controller "PaymentCtrl", [
		"$scope"
		"$rootScope"
		"$location"
		"$route"
		"$routeParams"
		"UserService"
		"PaymentService"
		"PricingService"
		"MenuService"
		"CartService"
		PaymentCtrl
	]
	return
