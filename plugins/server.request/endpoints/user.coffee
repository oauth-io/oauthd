db = require '../../../lib/db'
Url = require 'url'

fixUrl = (ref) -> ref.replace /^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2'


sendAbsentFeatureError = (req, res, feature) ->
	origin = null
	ref = fixUrl(req.headers['referer'] || req.headers['origin'] || "http://localhost");
	urlinfos = Url.parse(ref)
	if not urlinfos.hostname
		ref = origin = "http://localhost"
	else
		origin = urlinfos.protocol + '//' + urlinfos.host
	res.setHeader 'Access-Control-Allow-Origin', origin
	res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE'
	res.send 501, "This provider does not support the " + feature + " feature yet"

module.exports = (server, callback) ->
	server.get new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/endpoint:me$'), (req, res, next) -> 
		db.providers.getSettings req.params[0], (err, content) ->
			if !err
				if content.settings?.endpoints?.me?.url
					req.params[1] = encodeURIComponent(content.settings.endpoints.me.url);
					next()
				else
					return sendAbsentFeatureError req, res, 'me()'
			else
				return sendAbsentFeatureError req, res, 'me()'
	, callback