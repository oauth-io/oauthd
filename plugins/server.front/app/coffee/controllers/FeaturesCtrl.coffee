"use strict"
define [], () ->
	FeaturesCtrl = (UserService, MenuService) ->
		MenuService.changed()

	return [
		'UserService', 
		'MenuService', 
		FeaturesCtrl
	]
