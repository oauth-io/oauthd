
request = require 'request'

clientSessions = require 'client-sessions'

exports.setup = (callback) ->

	@server.use clientSessions
		cookieName: 'test_sessionkey',
		secret: "sdfghjjgfd",
		path: '/auth/test',
		duration: 24 * 60 * 60 * 1000,
		httpOnly: true,
		secure: true

	send_view = (req, res, data, next) =>
		res.setHeader 'Content-Type', 'text/html'
		csrf_token = @db.generateUid()
		req.test_sessionkey.csrf_tokens ?= "[]"
		csrf_tokens = JSON.parse(req.test_sessionkey.csrf_tokens)
		csrf_tokens.push csrf_token
		req.test_sessionkey.csrf_tokens = JSON.stringify(csrf_tokens)
		view = '<html><head>\n'
		view += '<script src="https://code.jquery.com/jquery.min.js"></script>\n'
		view += '<script src="/auth/download/latest/oauth.js"></script>\n'
		view += '<script>\n'
		view += 'function cons() {\n'
		view += '  $("#content").append("<div style=\\"color:" + cons.color + "\\">");\n'
		view += '  for (var i in arguments) {\n'
		view += '    var o = arguments[i];\n'
		view += '    if (typeof o == "object") o = JSON.stringify(o);\n'
		view += '    $("#content").append("<span>" + o + "</span> ");\n'
		view += '  }\n'
		view += '  $("#content").append("</div>");\n'
		view += '}\n'
		view += 'cons.log=function(){cons.color="black";cons.apply(null,arguments);};\n'
		view += 'cons.error=function(){cons.color="red";cons.apply(null,arguments);};\n'
		view += 'OAuth.initialize("_aR5on_YHZk7HH86EJRgzkA9sW0");\n'
		view += data.code if data.code
		view += 'function auth() {\n'
		view += data.auth.replace(/\[\[state\]\]/g, '"' + csrf_token + '"') if data.auth
		view += '}\n'
		view += '</script>\n'
		view += '</head>\n'
		view += '<body><button onclick="auth()">Authenticate</button><br/>\n'
		view += '<div id="content"></div>\n'
		view += '</body></html>'
		res.send view
		next()

	# server-side test: popup
	@server.get @config.base + '/test/srv/popup', (req, res, next) =>
		auth =  'OAuth.popup("salesforce", {state:[[state]]}, function(e,r) {\n'
		auth += '  if (e) return cons.error("callback error", e);\n'
		auth += '  cons.log ("sending code", r);\n'
		auth += '  $.ajax("/auth/test/auth", {type:"post", data:{code:r.code}, success:function(data) {\n'
		auth += '    cons.log ("result", data);\n'
		auth += '  }});\n'
		auth += '});\n'
		send_view req, res, auth:auth, next

	# server-side test: redirect
	@server.get @config.base + '/test/srv/redirect', (req, res, next) =>
		code =  'OAuth.callback(function(e,r) {\n'
		code += '  if (e) return cons.error("callback error", e);\n'
		code += '  console.log ("sending code", r);\n'
		code += '  $.ajax("/auth/test/auth", {type:"post", data:{code:r.code}, success:function(data) {\n'
		code += '    cons.log ("result", data);\n'
		code += '  }});\n'
		code += '});\n'

		auth =  'OAuth.redirect("salesforce", {state:[[state]]}, "/auth/test/srv/redirect");\n'
		send_view req, res, code:code, auth:auth, next

	# client-side test: popup
	@server.get @config.base + '/test/popup', (req, res, next) =>
		auth =  'OAuth.popup("salesforce", {state:[[state]]}, function(e,r) {\n'
		auth += '  if (e) return cons.error("callback error", e);\n'
		auth += '  cons.log ("result", r);\n'
		auth += '});\n'
		send_view req, res, auth:auth, next

	# client-side test: redirect
	@server.get @config.base + '/test/redirect', (req, res, next) =>
		code =  'OAuth.callback(function(e,r) {\n'
		code += '  if (e) return cons.error("callback error", e);\n'
		code += '  cons.log ("result", r);\n'
		code += '});\n'

		auth =  'OAuth.redirect("salesforce", {state:[[state]]}, "/auth/test/redirect");\n'
		send_view req, res, code:code, auth:auth, next

	@server.post @config.base + '/test/auth', (req, res, next) =>
		request.post {
			url: 'https://oauth.local/auth/access_token',
			form: {code:req.body.code}
		}, (e,r,body) =>
			res.setHeader 'Content-Type', 'text/html'
			data = JSON.parse(body)
			req.test_sessionkey.csrf_tokens ?= "[]"
			csrf_tokens = JSON.parse(req.test_sessionkey.csrf_tokens)
			if csrf_tokens.indexOf(data.state) == -1
				res.send "Oups, state does not match !"
				return next()
			res.send "Hai! State match & i got " + body
			next()

	callback()