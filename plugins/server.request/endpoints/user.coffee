module.exports = (server, callback) ->
	server.get new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/endpoint:me$'), (req, res, next) -> 
		console.log "PARAM", req.params
		req.params[1] = encodeURIComponent('/v1/people/~:(first-name,last-name,headline,picture-url)?format=json')
		next()
	, callback
	