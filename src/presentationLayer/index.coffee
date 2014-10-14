restify = require 'restify'
fs = require 'fs'



module.exports = (env) ->

	api = require('./api')(env)
	sdk = require('./sdk')(env)
	auth = require('./auth')(env)

	env.server.send = env.send = (res, next) -> (e, r) ->
		return next(e) if e
		res.send (if r? then r else env.utilities.check.nullv)
		next()

	api.init()

	env.server.use (req, res, next) ->
		res.setHeader 'Content-Type', 'application/json'
		next()

	env.bootPathCache = =>
		chain = restify.conditionalRequest()
		chain.unshift (req, res, next) =>
			res.set 'ETag', env.data.generateHash req.path() + ':' + env.config.bootTime
			next()
		return chain

	env.cors_middleware = (req, res, next) ->
		res.setHeader 'Access-Control-Allow-Origin', '*'
		res.setHeader 'Access-Control-Allow-Methods', 'GET'
		next()
		
	env.fixUrl = (ref) => ref.replace /^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2'

	
	sdk.registerWs()
	api.registerWs()
	auth.registerWs()