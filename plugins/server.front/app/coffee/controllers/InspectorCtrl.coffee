"use strict"
define [
	"app",
	'services/ProviderService',
	'services/AppService',
	'services/KeysetService',
	'services/OAuthIOService'
	], (app) ->
		InspectorCtrl = (UserService, ProviderService, AppService, KeysetService, OAuthIOService) ->
			alert 'hello'
			console.log "------------------------------------------------------|\n" +
						"| Hacker side - OAuth.io                              |\n" +
						"|                                                     |\n" +
						"| Type help() to get the list of command available    |\n" +
						"|                                                     |\n" +
						"| You can directly try OAuth.io SDK                   |\n" +
						"|                                                     |\n" +
						"| e.g.                                                |\n" +
						"| OAuth.popup('facebook', function)                   |\n" +
						"|                                                     |\n" +
						"| Thanks for trying us! <3                            |\n" +
						"------------------------------------------------------|"
			fctAvailable = [
				"provider.list"
				"user.register"
				"user.isLogin"
				"user.logout"
				"user.login"
				"user.me"
				"app.get"
				"app.create"
				"app.update"
				"app.remove"
				"keyset.get"
				"keyset.add"
				"keyset.remove"
				"contact"
			]

			window.provider =
				list: ->
					ProviderService.list ((data) ->
						console.log data
					), (err) ->
						console.log err

			window.user =
				login: (mail, pass) ->
					UserService.login {mail: mail, pass: pass}, ((data) ->
						console.log data
					), (err) -> console.log err
				register: (mail) ->
					UserService.register mail, ((data) ->
						console.log data
					), (err) ->
						console.log err
				isLogin: -> console.log UserService.isLogin()
				me: -> console.log UserService.me((data)-> console.log data)

			window.app =
				get: (publicKey) ->
					AppService.get publicKey, ((data) ->
						console.log data
					), (err) ->
						console.log err
				edit: (publicKey, name, domains) ->
					AppService.edit publicKey, {
						name: name,
						domains: domains
					}, ((data) ->
						console.log data
					), (err) ->
						console.log err
				remove: (publicKey) ->
					AppService.remove publicKey

			window.keyset =
				get: (publicKey, provider) ->
					KeysetService.get publicKey, provider, ((data) ->
						console.log data
					), (err) ->
						console.log err

				add: (publicKey, provider, keys) ->
					KeysetService.add publicKey, provider, keys ((data) ->
						console.log data
					), (err) ->
						console.log err
				remove: (publicKey, provider) ->
					KeysetService.remove publicKey, provider, ((data) ->
						console.log data
					), (err) ->
						console.log err

			window.contact = (from_email, from_name, subject, body) ->
				OAuthIOService.sendMail {
					from:
						mail: from_email,
						name: from_name,
					subject: subject,
					body: body
				}, ((data) ->
					console.log data
				), (err) ->
					console.log err


			window.help = ()->
				# if not fct or not fctAvailable[fct]
				console.log "Help\n" +
				"====\n" +
				"\n" +
				"SDK\n" +
				"---\n" +
				"\n" +
				"OAuth.initialize(publicKey)                    - Initialize the SDK with your key\n" +
				"OAuth.popup(provider, callback)                - Authorize yourself to an OAuth provider in popup mode\n" +
				"OAuth.redirect(provider, url)                  - Authorize yourself to an OAuth provider in redirect mode\n" +
				"\n" +
				"API Functions\n" +
				"-------------\n" +
				"\n" +
				"PROVIDER\n" +
				"provider.list()                                - Get the list of providers available\n" +
				"\n" +
				"USER\n" +
				"user.register(mail)                            - Sign up to OAuth.io\n" +
				"user.login(mail, pass)                         - Connect to your account\n" +
				"logout()                                       - Log out\n" +
				"user.me()                                      - Retrieve your user data\n" +
				"\n" +
				"APP\n" +
				"app.get(publicKey)                             - Get your app's information based on your app's public key\n" +
				"app.create(name, domains)                      - Create an app\n" +
				"app.edit(publicKey, data)                      - Edit your app's information\n" +
				"app.remove(publicKey)                          - Remove your app (no joke, it's really deleted!)\n" +
				"\n" +
				"KEYSET\n" +
				"keyset.get(publicKey, provider)                - Get the keyset associated with an app and a provider\n" +
				"keyset.add(publicKey, provider, keys)			- Add keys associated with an app and a provider\n" +
				"keyset.remove(publicKey, provider)             - Remove a keyset (no joke, it's really deleted!)\n" +
				"\n" +
				"CONTACT US :)\n" +
				"contact(from_email, from_name, object, body)   - Get in touch with our team\n" +
				"\n" +
				"You want to get this API on your own server? https://github.com/oauth-io/oauthd"
				return "200 OK"

		app.register.controller "InspectorCtrl", [
			"UserService"
			"ProviderService"
			"AppService"
			"KeysetService"
			"OAuthIOService"
			InspectorCtrl
		]
		return