define [
	"services/AppService"
	"services/UserService",
	"services/NotificationService",
	"services/CartService",
	"services/KeysetService",
	"services/MenuService",
	"services/OAuthIOService",
	"services/PaymentService",
	"services/PricingService",
	"services/ProviderService",
	"services/WishlistService"
	], (AppService, UserService, NotificationService, CartService, KeysetService, MenuService, OAuthIOService, PaymentService, PricingService, ProviderService, WishlistService) ->
		(app) ->
    		app.register.factory 'AppService', AppService
    		app.register.factory 'NotificationService', NotificationService
    		app.register.factory 'UserService', UserService
    		app.register.factory 'CartService', CartService
    		app.register.factory 'KeysetService', KeysetService
    		app.register.factory 'MenuService', MenuService
    		app.register.factory 'OAuthIOService', OAuthIOService,
    		app.register.factory 'PaymentService', PaymentService
    		app.register.factory 'PricingService', PricingService
    		app.register.factory 'ProviderService', ProviderService
    		app.register.factory 'WishlistService', WishlistService
    		return