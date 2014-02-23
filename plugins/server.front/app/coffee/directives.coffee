app.directive 'stubborn', ($rootScope, $timeout) ->
	def =
		restrict: 'A'
		templateUrl: '/templates/partials/stubborn.html'
		link: ($scope, tElement, tAttrs, ctrl) ->
			state = stepn:1, deep:0
			if $rootScope.timeouts
				for timer in $rootScope.timeouts
					$timeout.cancel timer

			$rootScope.timeouts = []
			getNext = ->
				state.deep++
				state = stubborn state if ! state.res?.length
				lastres = state.res.shift();
				if lastres.msg
					$('#stubborn-steps').append('<tr style="font-size: 0.8em"><td><span class="badge badge-info">' + lastres.stepn + '</span></td><td style="padding-left: 15px"> ' + lastres.msg + '</td></tr>')
					$('#stubborn-steps tr').last().hide().fadeIn();
					$rootScope.timeouts.push $timeout getNext, 2500
				if lastres.comment
					$('#programer').parent().attr('data-original-title', lastres.comment).attr('data-html','true').tooltip('show')
					$rootScope.timeouts.push $timeout (-> $('#programer').parent().tooltip('hide')),2000
					$rootScope.timeouts.push $timeout getNext, 3500
				lis = $('#stubborn-steps tr')
				if lis.length > 8
					lis.first().remove()
			$rootScope.timeouts.push $timeout getNext, 500

	return def

app.directive 'googleAnalytics', ($location, $rootScope, $window) ->
	return {
		scope: true,
		link: ($scope) ->
			$scope.$on '$routeChangeSuccess', ->
				$rootScope.location = $location.path()
				if $location.ga_skip
					$location.ga_skip = false
					return
				ga 'send', 'pageview', $location.path()
				_cio.page $location.absUrl()
	}

app.directive 'selectize', ($timeout) ->
    return {
        restrict: 'A',
        link: (scope, element, attrs) ->
            $timeout ->
                $(element).selectize scope.$eval(attrs.selectize)
    }

app.directive 'bootstrapModal', () ->
	def =
		restrict: 'A'
		scope: false
		link: ($scope, tElement, tAttrs, Ctrl) ->
			#console.log $(tElement)
			#console.log tAttrs
			$scope.$on 'btShow', ->
				$(tElement).modal 'show'
			$scope.$on 'btHide', ->
				$(tElement).modal 'hide'

app.directive 'lightbox', ($timeout) ->
	def =
		restrict: 'A'
		scope: false
		template: '<div class="modal">
	<div class="modal-dialog">
	    <div class="modal-content">
	    	<div class="modal-body">
				<img class="img-responsive" ng-src="{{lightbox.img}}" id="lightbox-img">
			</div>
			<div class="modal-footer">
				<p style="text-align: center" class="caption" id="lightbox-caption">{{lightbox.caption}}</p>
			</div>
		</div>
	</div>
</div>'
		link: ($scope, tElement, tAttrs, Ctrl) ->
			$scope.lightbox =
				show: false
				img: ""
				caption: ""
				debug: false

			$scope.showLightbox = (img, caption)->
				$(tElement).modal('show').find('.modal').show()
				$('.modal-backdrop').css('opacity', 0.5)
				$scope.lightbox.show = true
				$scope.lightbox.img = img
				$scope.lightbox.caption = caption
				$scope.lightbox.debug = true


			$('body').click ->
				if $scope.lightbox.debug == true
					$scope.lightbox.debug = false
				else
					if $scope.lightbox.show
						$(tElement).modal('hide').find('.modal').hide()
						$('.modal-backdrop').remove()


app.directive "fiddleIframe", ->
	linkFn = (scope, element, attrs) ->
		element.find("iframe").bind "load", (event) ->
			scope.ngLoad();
	dir = 
		restrict: "EA",
		scope:
			src: "@src"
			height: "@height"
			width: "@width"
			scrolling: "@scrolling"
			ngLoad: "="
			allowFullScreen: '@allowfullscreen',
		template: '<iframe class="frame" allowfullscreen="{{ allowfullscreen }}" height="{{height}}" width="{{width}}" frameborder="0" border="0" marginwidth="0" marginheight="0" scrolling="{{scrolling}}" src="{{src}}"></iframe>'
		link: linkFn
	return dir


# app.directive 'paymentform', () ->
# 	def =
# 		restrict: 'E'
# 		scope: true
# 		transclude: true
# 		templateUrl: '../templates/partials/payment-form.html'


# app.directive 'addressform', () ->
# 	def =
# 		restrict: 'E'
# 		scope: true
# 		transclude: true
# 		relace: true
# 		templateUrl: '../templates/partials/address-form.html'
# 		link: ($scope, tElement, tAttrs, Ctrl) ->
