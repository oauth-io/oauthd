module.exports = (env) ->
	sdk_js = require('./sdk_js')(env)

	init: () ->
		return
	registerWs: () ->
		# generated js sdk
		env.server.get '/auth/download/latest/oauth.js', env.bootPathCache(), (req, res, next) ->
			sdk_js.get (e, r) ->
				return next e if e
				res.setHeader 'Content-Type', 'application/javascript'
				res.send r
				next()

		# generated js sdk minified
		env.server.get '/auth/download/latest/oauth.min.js', env.bootPathCache(), (req, res, next) ->
			sdk_js.getmin (e, r) ->
				return next e if e
				res.setHeader 'Content-Type', 'application/javascript'
				res.send r
				next()