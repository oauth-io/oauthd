define [], () ->
	MenuService = ($http, $rootScope, $location) ->
		$rootScope.selectedMenu = $location.path()

		obj =
			changed: (async) ->
				p = $location.path()

				$rootScope.selectedMenu = $location.path()
				setTimeout (=>
					@loaded() if not async
				), 100

			loaded: ->
				h = $(window).height()
				t = $('body').height()
				h2 = $('#content').height()
				console.log h, h2, t, h < t
				if h > t
					n = $('#content .flexible').length
					m = (h - t) / (2 * n)
					$('.flexible').css 'margin', m + 'px 0px'
				else if h + 90 > t
					n = $('#content .flexible').length
					m = (h + 90 - t) / (2 * n)
					$('.flexible').css 'margin', m + 'px 0px'

		return obj
	return ["$http", "$rootScope", "$location", MenuService]