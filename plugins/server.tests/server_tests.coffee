
request = require 'request'

clientSessions = require 'client-sessions'

exports.setup = (callback) ->

	@server.use clientSessions
		cookieName: 'test_sessionkey',
		secret: "sdfghjjgfd",
		path: '/auth/test',
		duration: 24 * 60 * 60 * 1000,
		httpOnly: true,
		secure: false

	provider = "salesforce"
	auth_button_id = 0
	auth_code = ""
	body_code = ""
	add_button = (name, code) =>
		button_id = "auth_" + auth_button_id++
		auth_code += "function " + button_id + "() {\n"
		auth_code += code
		auth_code += "}\n"
		body_code += '<button onclick="' + button_id + '()">' + name + '</button><br />\n'
		return button_id

	add_separator = (name) =>
		body_code += '<hr/><h1>' + name + '</h1><br />\n'

	init_tests = (req, res, next) =>
		auth_button_id = 0
		auth_code = ""
		body_code = ""
		next()

	send_view = (req, res, next) =>
		res.setHeader 'Content-Type', 'text/html'
		csrf_token = @db.generateUid()
		req.test_sessionkey.csrf_tokens ?= "[]"
		csrf_tokens = JSON.parse(req.test_sessionkey.csrf_tokens)
		csrf_tokens.push csrf_token
		if (csrf_tokens.length > 3)
			csrf_tokens.shift();
		console.log "added token", csrf_token
		req.test_sessionkey.csrf_tokens = JSON.stringify(csrf_tokens)
		console.log "after adding token", req.test_sessionkey.csrf_tokens
		view = '<html><head>\n'
		view += '<script src="/lib/jquery/jquery2.js"></script>\n'
		view += '<script src="/auth/download/latest/oauth.min.js"></script>\n'
		view += '<script>\n'
		view += 'var state="' + csrf_token + '";\n'
		view += 'var initialized = false;\n'
		view += 'var cons_list = [];\n'
		view += 'function cons() {\n'
		view += '  if ( ! initialized) {\n'
		view += '    var col=cons.color;\n'
		view += '    var args=arguments;\n'
		view += '    cons_list.push(function() {cons.color=col;cons.apply(null,args);});\n'
		view += '    return;\n'
		view += '  }\n'
		view += '  console[{"black":"log","red":"error"}[cons.color]].apply(console, arguments);\n'
		view += '  $("#content").append("<div style=\\"color:" + cons.color + "\\">");\n'
		view += '  for (var i in arguments) {\n'
		view += '    var o = arguments[i];\n'
		view += '    if (typeof o == "object") o = JSON.stringify(o);\n'
		view += '    $("#content").append("<span>" + o + "</span> ");\n'
		view += '  }\n'
		view += '  $("#content").append("</div>");\n'
		view += '}\n'
		view += '$(document).ready(function() {\n'
		view += '  initialized = true;\n'
		view += '  for (var i in cons_list) {\n'
		view += '    cons_list[i].apply(null,[]);\n'
		view += '  }\n'
		view += '});\n'
		view += 'cons.log=function(){cons.color="black";cons.apply(null,arguments);};\n'
		view += 'cons.error=function(){cons.color="red";cons.apply(null,arguments);};\n'
		view += 'OAuth.initialize("_aR5on_YHZk7HH86EJRgzkA9sW0");\n'
		view +=  'OAuth.callback(function(e,r) {\n'
		view += '  if (e) return cons.error("callback error", e);\n'
		view += '  if (! r.code) return cons.log("there is no code in result");\n'
		view += '  cons.log ("sending code", r);\n'
		view += '  $.ajax("/auth/test/auth", {type:"post", data:{code:r.code}, success:function(data) {\n'
		view += '    cons.log ("result", data);\n'
		view += '  }});\n'
		view += '});\n'
		view += auth_code
		view += '</script>\n'
		view += '</head>\n'
		view += '<body>\n'
		view += body_code
		view += '<div id="content"></div>\n'
		view += '</body></html>'
		res.send view
		next()

	@server.get @config.base + '/test/all', init_tests, (req, res, next) =>
		add_separator 'Working samples'

		auth =  'OAuth.popup("' + provider + '", {state:state}, function(e,r) {\n'
		auth += '  if (e) return cons.error("callback error", e);\n'
		auth += '  cons.log ("sending code", r);\n'
		auth += '  $.ajax("/auth/test/auth", {type:"post", data:{code:r.code}, success:function(data) {\n'
		auth += '    cons.log ("result", data);\n'
		auth += '  }});\n'
		auth += '});\n'
		add_button 'server-side auth, popup', auth

		auth =  'OAuth.redirect("' + provider + '", {state:state}, "/auth/test/all");\n'
		add_button 'server-side auth, redirect', auth

		auth =  'OAuth.popup("' + provider + '", function(e,r) {\n'
		auth += '  if (e) return cons.error("callback error", e);\n'
		auth += '  cons.log ("result", r);\n'
		auth += '});\n'
		add_button 'client-side auth, popup', auth

		auth =  'OAuth.popup("' + provider + '", {authorize:{display:"popup"}}, function(e,r) {\n'
		auth += '  if (e) return cons.error("callback error", e);\n'
		auth += '  cons.log ("result", r);\n'
		auth += '});\n'
		add_button 'client-side auth, popup, display=popup', auth

		auth =  'OAuth.redirect("' + provider + '", "/auth/test/all");\n'
		add_button 'client-side auth, redirect', auth

		add_separator 'Errors samples'
		auth =  'OAuth.popup("' + provider + '", function(e,r) {\n'
		auth += '  if (e) return cons.error("callback error", e);\n'
		auth += '  cons.log ("sending code", r);\n'
		auth += '  $.ajax("/auth/test/auth", {type:"post", data:{code:r.code}, success:function(data) {\n'
		auth += '    cons.log ("result", data);\n'
		auth += '  }});\n'
		auth += '});\n'
		add_button 'server-side auth, popup | missing state', auth

		auth =  'OAuth.redirect("' + provider + '", "/auth/test/all");\n'
		add_button 'server-side auth, redirect | missing state ', auth

		send_view req, res, next

	@server.post @config.base + '/test/auth', (req, res, next) =>
		request.post {
			url: 'https://oauth.local/auth/access_token'
			form:
				code: req.body.code
				key: "_aR5on_YHZk7HH86EJRgzkA9sW0"
				secret: "BB19B3RQ3L2DXjg-QN6wsIai1K4"
		}, (e,r,body) =>
			res.setHeader 'Content-Type', 'text/html'
			data = JSON.parse(body)
			req.test_sessionkey.csrf_tokens ?= "[]"
			csrf_tokens = JSON.parse(req.test_sessionkey.csrf_tokens)
			if not data.state
				res.send "Got error:" + body
				return next()
			if csrf_tokens.indexOf(data.state) == -1
				console.log "not matching", req.test_sessionkey.csrf_tokens, data.state
				res.send "Oups, state does not match !"
				return next()
			res.send "Hai! State match & i got " + body
			next()

	callback()