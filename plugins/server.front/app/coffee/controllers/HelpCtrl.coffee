"use strict"
define [], () ->
	HelpCtrl = (UserService, MenuService) ->
		MenuService.changed()

	return [
		'UserService', 
		'MenuService', 
		HelpCtrl
	]