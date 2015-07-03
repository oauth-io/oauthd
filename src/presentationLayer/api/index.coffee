restify = require 'restify'
async = require 'async'
fs = require 'fs'
Path = require 'path'
Url = require 'url'

engine = {}
module.exports = (env) ->
	init: () ->
		env.server.opts /^\/api\/.*$/, (req, res, next) =>
			res.setHeader "Access-Control-Allow-Origin", "*"
			res.setHeader "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"
			res.setHeader "Access-Control-Allow-Headers", "Authorization, Content-Type"
			res.send(200);

		env.server.use (req, res, next) =>
			if (req.url.match(/^\/api\/.*$/))
				res.setHeader "Access-Control-Allow-Origin", "*"
				res.setHeader "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"
				res.setHeader "Access-Control-Allow-Headers", "Authorization, Content-Type"
			next()

	registerWs: () ->
		# create an application
		env.server.post '/api/apps', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.create req.body, req.user, (error, result) =>
				return next(error) if error
				env.events.emit 'app.create', req.user, result
				res.send name:result.name, key:result.key, domains:result.domains
				next()

		# get infos of an app
		env.server.get '/api/apps/:key', env.middlewares.auth.needed, (req, res, next) =>
			async.parallel [
				(cb) => env.data.apps.get req.params.key, cb
				(cb) => env.data.apps.getDomains req.params.key, cb
				(cb) => env.data.apps.getKeysets req.params.key, cb
				(cb) => env.data.apps.getBackend req.params.key, cb
			], (e, r) =>
				return next(e) if e
				app = r[0]
				delete app.id
				app.domains = r[1]
				app.keysets = r[2]
				app.backend = r[3]
				res.send app
				next()

		# update infos of an app
		env.server.post '/api/apps/:key', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.update req.params.key, req.body, env.send(res,next)

		# remove an app
		env.server.del '/api/apps/:key', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.get req.params.key, (e, app) =>
				return next(e) if e
				env.data.apps.remove req.params.key, (e, r) =>
					return next(e) if e
					env.events.emit 'app.remove', req.user, app
					res.send env.utilities.check.nullv
					next()

		# reset the public key of an app
		env.server.post '/api/apps/:key/reset', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.resetKey req.params.key, env.send(res,next)

		# list valid domains for an app
		env.server.get '/api/apps/:key/domains', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.getDomains req.params.key, env.send(res,next)

		# update valid domains list for an app
		env.server.post '/api/apps/:key/domains', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.updateDomains req.params.key, req.body.domains, env.send(res,next)

		# add a valid domain for an app
		env.server.post '/api/apps/:key/domains/:domain', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.addDomain req.params.key, req.params.domain, env.send(res,next)

		# remove a valid domain for an app
		env.server.del '/api/apps/:key/domains/:domain', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.remDomain req.params.key, req.params.domain, env.send(res,next)

		# list keysets (provider names) for an app
		env.server.get '/api/apps/:key/keysets', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.getKeysets req.params.key, env.send(res,next)

		# get a keyset for an app and a provider
		env.server.get '/api/apps/:key/keysets/:provider', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.getKeyset req.params.key, req.params.provider, env.send(res,next)

		# add or update a keyset for an app and a provider
		env.server.post '/api/apps/:key/keysets/:provider', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.addKeyset req.params.key, req.params.provider, req.body, env.send(res,next)

		# remove a keyset for a app and a provider
		env.server.del '/api/apps/:key/keysets/:provider', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.remKeyset req.params.key, req.params.provider, env.send(res,next)

		# get providers list
		env.server.get '/api/providers', env.middlewares.auth.optional, (req, res, next) =>
			env.data.providers.getList env.send(res,next), req.user

		# get the backend of an app
		env.server.get '/api/apps/:key/backend', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.getBackend req.params.key, env.send(res,next)

		# set or update the backend for an app
		env.server.post '/api/apps/:key/backend/:backend', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.setBackend req.params.key, req.params.backend, req.body, env.send(res,next)

		# remove a backend from an app - server_side only
		env.server.del '/api/apps/:key/backend', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.remBackend req.params.key, env.send(res,next)

		# get the app's options
		env.server.get '/api/apps/:key/options', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.getOptions req.params.key, env.send(res, next)

		# set the app's options
		env.server.post '/api/apps/:key/options', env.middlewares.auth.needed, (req, res, next) =>
			env.data.apps.setOptions req.params.key, req.body, env.send(res, next)

		# get a provider config
		env.server.get '/api/providers/:provider', env.cors_middleware, (req, res, next) =>
			if req.query.extend
				env.data.providers.getExtended req.params.provider, env.send(res,next)
			else
				env.data.providers.get req.params.provider, env.send(res,next)

		# get a provider config's extras
		env.server.get '/api/providers/:provider/settings', env.cors_middleware, (req, res, next) =>
			env.data.providers.getSettings req.params.provider, env.send(res,next)

		# get the provider me.json mapping configuration
		env.server.get '/api/providers/:provider/user-mapping', env.cors_middleware, (req, res, next) =>
			env.data.providers.getMeMapping req.params.provider, env.send(res,next)

		# get a provider logo
		env.server.get '/api/providers/:provider/logo', env.bootPathCache(), ((req, res, next) =>
			env.middlewares.providerLogo ?= (req, res, next) -> next()
			fs.exists Path.normalize(env.config.rootdir + '/providers/' + req.params.provider), (exists) =>
				if not exists
					env.middlewares.providerLogo req, res, next
				else
					fs.exists Path.normalize(env.config.rootdir + '/providers/' + req.params.provider + '/logo.png'), (exists) =>
						if not exists
							req.params.provider = 'default'
						req.url = '/' + req.params.provider + '/logo.png'
						req._url = Url.parse req.url
						req._path = req._url._path
						next()
					), restify.serveStatic
						directory: env.config.rootdir + '/providers'
						maxAge: env.config.cacheTime
			
		# get a provider file
		env.server.get '/api/providers/:provider/:file', env.bootPathCache(), ((req, res, next) =>
				req.url = '/' + req.params.provider + '/' + req.params.file
				req._url = Url.parse req.url
				req._path = req._url._path
				next()
			), restify.serveStatic
				directory: env.config.rootdir + '/providers'
				maxAge: env.config.cacheTime

		# get the plugins list
		env.server.get '/api/plugins', env.middlewares.auth.needed, (req, res, next) =>
			env.scaffolding.plugins.info.getPluginsJson({activeOnly: true})
					.then (data) ->
						res.send Object.values data
					.fail (e) ->
						env.debug e
						res.send 400, 'Error reading the plugins data'

		# get one plugin info
		env.server.get '/api/plugins/:plugin_name', env.middlewares.auth.needed, (req, res, next) =>
			env.scaffolding.plugins.info.getInfo(req.params.plugin_name)
					.then (data) ->
						res.send data
					.fail (e) ->
						env.debug e
						res.send 400, 'Error reading the plugin data'

		# get host_url
		env.server.get '/api/host_url', env.middlewares.auth.needed, (req, res, next) =>
			res.send env.config.host_url
			next()

		# get env.config
		env.server.get '/api/config', env.middlewares.auth.needed, (req, res, next) =>
			res.send env.config
			next()

		# get generated api endpoints
		env.server.get '/api/extended-endpoints', (req, res, next) ->
			res.send env.pluginsEngine.getExtendedEndpoints()
			next()

