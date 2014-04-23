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
				n = $('#content .flexible').length
				return false if n == 0
				winHeight = $(window).height()
				bodyHeight = $('body').height() - 42

				sup = 90
				if winHeight > 900
					sup = 10

				m = winHeight - bodyHeight + sup
				m = 400 if m > 400

				if m > 0
					@lastMargin = m
					$('#content .flexible').css 'margin', (m / (2 * n)) + 'px 0px'
				else
					@lastMargin = 0

				$(window).on 'resize', =>
					n = $('#content .flexible').length
					winHeight = $(window).height()
					bodyHeight = $('body').height() - @lastMargin

					sup = 90
					if winHeight > 900
						sup = 0

					m = winHeight - bodyHeight + sup
					m = 400 if m > 400
					if m > 0 && n > 0
						@lastMargin = m
						$('#content .flexible').css 'margin', (m / (2 * n)) + 'px 0px'
					else
						@lastMargin = 0

		return obj
	return ["$http", "$rootScope", "$location", MenuService]