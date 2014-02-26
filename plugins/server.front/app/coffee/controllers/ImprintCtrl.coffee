"use strict"
define [], () ->
	ImprintCtrl = (MenuService) ->
		MenuService.changed()
		
	return [
		'MenuService', 
		ImprintCtrl
	]