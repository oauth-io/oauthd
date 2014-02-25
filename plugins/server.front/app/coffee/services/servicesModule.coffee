define [
	"services/AppService"
	"services/UserService",
	"services/NotificationService"
	], (AppService, UserService, NotificationService) ->
		(app) ->
    		app.register.factory 'AppService', AppService
    		app.register.factory 'UserService', UserService
    		app.register.factory 'NotificationService', NotificationService
    		return