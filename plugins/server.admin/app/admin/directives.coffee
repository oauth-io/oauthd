# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

hooks.config.push ->
	app.directive 'bootstrapModal', ->
		restrict: 'A'
		scope: false
		link: ($scope, tElement, tAttrs, Ctrl) ->
			$scope.$on 'btShow', ->
				$(tElement).modal 'show'
			$scope.$on 'btHide', ->
				$(tElement).modal 'hide'

	app.directive 'lightbox', ($timeout) ->
		restrict: 'A'
		scope: false
		template: '<div class="modal">
	<div class="modal-dialog">
		<div class="modal-content">
			<div class="modal-body">
				<img ng-src="{{baseurl}}/{{lightbox.img}}" id="lightbox-img">
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
