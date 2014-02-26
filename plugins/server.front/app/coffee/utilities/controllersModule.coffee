define [
	"controllers/AboutCtrl",
	"controllers/ApiKeyManagerCtrl",
	"controllers/AppCtrl",
	"controllers/ContactUsCtrl",
	"controllers/DocsCtrl",
	"controllers/EditorCtrl",
	"controllers/FeaturesCtrl",
	"controllers/GeneralAccountCtrl",
	"controllers/HelpCtrl",
	"controllers/ImprintCtrl",
	"controllers/IndexCtrl",
	"controllers/LogoutCtrl",
	"controllers/NotFoundCtrl",
	"controllers/NotificationCtrl",
	"controllers/PaymentCtrl",
	"controllers/PricingCtrl",
	"controllers/ProviderAppCtrl",
	"controllers/ProviderAppKeyCtrl",
	"controllers/ProviderCtrl",
	"controllers/ProviderPageCtrl",
	"controllers/ProviderSampleCtrl",
	"controllers/ResetPasswordCtrl",
	"controllers/TermsCtrl",
	"controllers/UserFormCtrl",
	"controllers/UserProfileCtrl",
	"controllers/ValidateCtrl",
	"controllers/WishlistCtrl"
	], (AboutCtrl, 
		ApiKeyManagerCtrlm,
		AppCtrl,
		ContactUsCtrl,
		DocsCtrl,
		EditorCtrl,
		FeaturesCtrl,
		GeneralAccountCtrl,
		HelpCtrl,
		ImprintCtrl,
		IndexCtrl,
		LogoutCtrl,
		NotFoundCtrl,
		NotificationCtrl,
		PaymentCtrl,
		PricingCtrl,
		ProviderAppCtrl,
		ProviderAppKeyCtrl,
		ProviderCtrl,
		ProviderPageCtrl,
		ProviderSampleCtrl,
		ResetPasswordCtrl,
		TermsCtrl,
		UserFormCtrl,
		UserProfileCtrl,
		ValidateCtrl,
		WishlistCtr) ->
			(app) ->
				app.register.controller "AboutCtrl", AboutCtrl
				app.register.controller "ApiKeyManagerCtrlm", ApiKeyManagerCtrl
				app.register.controller "AppCtrl", AppCtrl
				app.register.controller "ContactUsCtrl", ContactUsCtrl
				app.register.controller "DocsCtrl", DocsCtrl
				app.register.controller "EditorCtrl", EditorCtrl
				app.register.controller "FeaturesCtrl", FeaturesCtrl
				app.register.controller "GeneralAccountCtrl", GeneralAccountCtrl
				app.register.controller "HelpCtrl", HelpCtrl
				app.register.controller "ImprintCtrl", ImprintCtrl
				app.register.controller "IndexCtrl", IndexCtrl
				app.register.controller "LogoutCtrl", LogoutCtrl
				app.register.controller "NotFoundCtrl", NotFoundCtrl
				app.register.controller "NotificationCtrl", NotificationCtrl
				app.register.controller "PaymentCtrl", PaymentCtrl
				app.register.controller "PricingCtrl", PricingCtrl
				app.register.controller "ProviderAppCtrl", ProviderAppCtrl
				app.register.controller "ProviderAppKeyCtrl", ProviderAppKeyCtrl
				app.register.controller "ProviderCtrl", ProviderCtrl
				app.register.controller "ProviderPageCtrl", ProviderPageCtrl
				app.register.controller "ProviderSampleCtrl", ProviderSampleCtrl
				app.register.controller "ResetPasswordCtrl", ResetPasswordCtrl
				app.register.controller "TermsCtrl", TermsCtrl
				app.register.controller "UserFormCtrl", UserFormCtrl
				app.register.controller "UserProfileCtrl", UserProfileCtrl
				app.register.controller "ValidateCtrl", ValidateCtrl
				app.register.controller "WishlistCtrl", WishlistCtrl
				return