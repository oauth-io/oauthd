"use strict"
define [], () ->
	AboutCtrl = (UserService, MenuService) ->
		MenuService.changed()

	return ['UserService', 'MenuService', AboutCtrl]