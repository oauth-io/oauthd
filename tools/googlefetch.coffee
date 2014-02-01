request = require 'request'
async = require 'async'
fs = require 'fs'
convert = require('netpbm').convert

root = __dirname + '/../'

extraglobal =
	addscopes:
		"openid": "Access to your id"
		"email": "Get access to your mail. The presence of email requests that the ID Token include email and email_verified claims, and that these values be included in the information available at the userinfo endpoint."
		"profile": "Get access to your profile. profile will provide an Access Token that can be used to obtain user profile information from the Userinfo endpoint. We recommend using Google+ Sign-In if your application needs user profile information because the Google+ APIs provide a richer set of data that can be controlled by the user"
		"https://www.googleapis.com/auth/gcm_for_chrome": "CloudMessaging for chrome"

extra =
	adexchangebuyer:
		merge: 'google_adexchange'
	adexchangeseller:
		merge: 'google_adexchange'
	adsensehost:
		merge: 'google_adsense'
	androidpublisher:
		merge: 'google_play'
	appstate:
		merge: 'google_play'
	coordinate:
		merge: 'google_maps'
	discovery:
		ignore: true
	freebase:
		addname: false
	doubleclickbidmanager:
		merge: 'google_doubleclick'
	doubleclicksearch:
		merge: 'google_doubleclick'
	games:
		merge: 'google_play'
	gamesManagement:
		merge: 'google_play'
	gan:
		merge: 'google_affiliate_network'
	groupsmigration:
		merge: 'google_groups'
	groupssettings:
		merge: 'google_groups'
	google_adexchange:
		name: "Google AdExchange"
	google_doubleclick:
		name: "Google DoubleClick"
		addscopes:
			"https://www.googleapis.com/auth/doubleclickbidmanager": "Read/write access to Bid Manager API"
			"https://www.googleapis.com/auth/doubleclicksearch": "Read/write access to Search API"
	google_licensing:
		addscopes:
			"https://www.googleapis.com/auth/apps.licensing": "Read/write access to License Manager API."
	google_play:
		name: "Google Play"
	oauth2:
		ignore: true
	orkut:
		addname: false
	plusDomains:
		merge: 'google_plus'
	reseller:
		merge: 'google_apps'
	siteVerification:
		merge: 'google_site'
	taskqueue:
		merge: 'google_tasks'
	youtube:
		addname: false
		name: 'YouTube'
	youtubeAnalytics:
		merge: 'youtube'


providers = {}

getApi = (infos, callback) ->
	request.get {
		url: infos.discoveryRestUrl
		json: true
	}, (err, res, body) ->
		return callback err if err

		provider_name = body.name.replace(/[A-Z]/, (d) -> "_" + d.toLowerCase())
		if not extra[infos.name] || extra[infos.name].addname != false
			provider_name = body.ownerName.toLowerCase() + "_" + provider_name

		merged = extra[infos.name]?.merge
		if extra[infos.name]?.merge
			provider_name = extra[infos.name].merge

		result = providers[provider_name] ?= {}

		api_name = body.title.replace(new RegExp(" API$"), "")
		if not extra[infos.name] || extra[infos.name].addname != false
			if not api_name.match(new RegExp(body.ownerName, "i"))
				api_name = body.ownerName + " " + api_name

		result.provider ?=
			name: extra[provider_name]?.name || api_name
			desc: extra[provider_name]?.description || body.description
			url: "https://accounts.google.com/o/oauth2"
			oauth2:
				authorize:
					url: "/auth"
					query:
						client_id: "{client_id}"
						response_type: "code"
						redirect_uri: "{{callback}}"
						state: "{{state}}"
						scope: "{scope}"
						access_type: "{access_type}"
				access_token:
					url: "/token"
					extra: ["id_token"]
				request: body.rootUrl
				refresh: "/token"
				revoke:
					url: "/revoke"
					method: "post"
					query:
						token: "{{token}}"
				parameters:
					client_id: "string"
					client_secret: "string"
					access_type:
						values:
							online: "Will not provide a refresh_token"
							offline: "/!\\ Please use server-side only /!\\ If your application needs to refresh access tokens when the user is not present at the browser"
						cardinality: "1"
			href:
				keys: "https://code.google.com/apis/console/",
				docs: body.documentationLink,
				apps: "https://code.google.com/apis/console/",
				provider: "http://google.com/"

		result.settings ?=
			settings:
				createApp:
					url: "https://code.google.com/apis/console/"
					image: "config.png"
				copyingKey:
					url: "https://code.google.com/apis/console/"
					image: "keys.png"
				install:
					href:
						provider: "http://#{body.ownerDomain}/"
						docs: body.documentationLink

		{provider, settings} = result
		provider.oauth2.parameters.scope ?= values: {}

		if not merged
			provider.name = extra[provider_name]?.name || api_name
			provider.desc = extra[provider_name]?.description || body.description

		result.logo_url = body.icons.x32
		if fs.existsSync(root + 'providers/' + provider_name + '/conf.json')
			result.hasScopes = true
			existing = JSON.parse fs.readFileSync(root+'providers/'+provider_name+'/conf.json', 'utf8')
			provider.href.provider = existing.href.provider if existing.href?.provider
			provider.desc = existing.desc if existing.desc
			for scope_name, scope_desc of existing.oauth2.parameters.scope.values
				provider.oauth2.parameters.scope.values[scope_name] = scope_desc

		settings.settings.install.href.provider = provider.href.provider

		if body.auth?.oauth2?.scopes
			result.hasScopes = true
			for scope_name, scope of body.auth.oauth2.scopes
				provider.oauth2.parameters.scope.values[scope_name] = scope.description

		if extra[provider_name]?.addscopes
			result.hasScopes = true
			for scope_name, scope_desc of extra[provider_name].addscopes
				provider.oauth2.parameters.scope.values[scope_name] = scope_desc

		for scope_name, scope_desc of extraglobal.addscopes
			provider.oauth2.parameters.scope.values[scope_name] = scope_desc
		callback null


generateProvider = (name) ->
	fs.mkdir root+'providers/' + name, (err,res) ->
		request {
			url: providers[name].logo_url
			encoding: null
		}, (err, res, img) ->
			ext = providers[name].logo_url.substr(providers[name].logo_url.length-3,3)
			fs.writeFile root+'providers/' + name + '/logo.'+ext, img, (err,res) ->
				if ext != 'png'
					convert root+'/providers/'+name+'/logo.'+ext, root+'/providers/'+name+'/logo.png', {}, (err) ->
						return console.error 'error while converting logo.' + ext + ' to logo.png:', err if err
						fs.unlink root+'providers/' + name + '/logo.'+ext, ->
			fs.writeFile root+'providers/' + name + '/conf.json', JSON.stringify(providers[name].provider,undefined,"\t"), 'utf8', ->
			fs.writeFile root+'providers/' + name + '/settings.json', JSON.stringify(providers[name].settings,undefined,"\t"), 'utf8', ->
			fs.readFile root+'providers/google/config.png', (err, res) ->
				fs.writeFile root+'providers/' + name + '/config.png', res, ->
			fs.readFile root+'providers/google/keys.png', (err, res) ->
				fs.writeFile root+'providers/' + name + '/keys.png', res, ->

request.get {
	url: 'https://www.googleapis.com/discovery/v1/apis'
	json: true
}, (err, res, body) ->
	cmds = []
	for api in body.items
		do (api) ->
			if api.preferred and not extra[api.name]?.ignore
				cmds.push (cb) ->
					getApi api, cb
	async.parallel cmds, (err, res) ->
		names = Object.keys(providers).sort()
		for name in names
			if not providers[name].hasScopes
				console.log "no scope: %s (%s)", name, providers[name].provider.name
		for name in names
			if providers[name].hasScopes
				console.log name, "\t\t", providers[name].provider.name
				generateProvider name