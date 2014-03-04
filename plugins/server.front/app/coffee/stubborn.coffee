"use strict"
define [], () ->
	stub = ->
		debugmode = true

		pickrandom = (arr) -> arr[Math.floor(Math.random() * arr.length)]

		# set flag
		_st = -> args = arguments; (s) -> s[n]=true for i,n of args; undefined
		_sf = -> args = arguments; (s) -> s[n]=false for i,n of args; undefined

		# check flag
		_t = (n) -> (s) -> s[n]
		_f = (n) -> (s) -> !s[n]
		_eq = (n,v) -> (s) -> s[n]==v

		# language extensions
		_exts = {'php':'php','javascript':'js','python':'py','ruby':'rb','java':'java'}

		# graph description
		nodes =
			start: [
				(_sf 'downloaded', 'readdoc', 'stablesite'),
				github:'',
				(_f 'searchoffsdk'), siteoff:''],

			# giveup methods
			giveup: [
				switchlanguage: ''
				start: ''
			],
			switchlanguage: [
				start: ((s) ->
					s.language = pickrandom Object.keys(_exts)
					pickrandom [
						'{language} is [better|faster|sexier|easier]!',
						"let's try in {language}!",
						"anyway i ll use {language}."
					]
				)
			],

			# select a site
			github: [ 'Go to [github|github|github|sourceforge|google code]',
				(_st 'stablesite'),
				searchsdk:'',
				(_f 'searchoffsdk'),
				searchoffsdk:'official...'],
			siteoff: [ 'Go to official download page',
				(_st 'searchoffsdk'),
				downloadlib:'official...',
				[(_f 'stablesite'), 0.1, error404:'']],

			# search & read doc of the lib
			searchoffsdk: [ 'Search official [SDK|lib]',
				(_sf 'downloaded'), (_st 'searchoffsdk'),
				downloadlib:''],
			searchsdk: [
				(_sf 'downloaded'),
				searchunoffsdk:''
				searchgeneric:''
				[(_f 'searchoffsdk'), searchoffsdk:'']],
			searchunoffsdk: [ 'Search unofficial [SDK|lib]',
				filterlang:'', downloadlib:''],
			searchgeneric: [ 'Search generic oauth lib',
				filterlang:'', downloadlib:''],
			filterlang: [ 'Filter by {language}',
				readdoc:'', downloadlib:''],
			readdoc: [ 'Read the documentation',
				(_st 'readdoc'),
				[(_f 'downloaded'), downloadlib:"looks nice!"],
				[(_t 'downloaded'), (_f 'installed'), installlib:'']
				[(_t 'downloaded'), (_t 'installed'), uselib:""],
				[0.2,searchsdk:['not easy..', "i don't understand", "wtf?"]],
				[0.05,giveup:"let's try something else"]]
			error404: ['404 not found',
				[(_eq 'language','python'), 'unknown domain: packages.python.org'],
				giveup:'well...'],

			# download, install & configure the lib
			downloadlib: [ 'Download the lib', '[Clone|Checkout] repository'
				(_st 'downloaded')
				(_sf 'initlib', 'fixsrc', 'bugkeys', 'bugobj', 'installed'),
				installlib:'',
				[(_f 'readdoc'), readdoc:'what about the doc?'],
				[(_f 'stablesite'), 0.2, error404:'']],
			installlib: [ 'Install the lib',
				[(_eq 'language','php'), postinstall:"**cp -R**"],
				[(_eq 'language','javascript'), postinstall:"**[bower|npm] install**"],
				[(_eq 'language','python'), postinstall:"**easy_install**..."],
				[(_eq 'language','ruby'), postinstall:"**gem install**..."],
				[(_eq 'language','java'), postinstall:["**ant**", "**maven java:compile**", "**mvn [compile|install]**"]]],
			postinstall: [
				[(_eq 'language','javascript'), error:['npm ERR! not with npm itself.', 'make: node-waf: Command not found', 'npm ERR! `sh "-c" "node-gyp rebuild"` failed with 1']],
				[(_eq 'language','php'), error:['Warning: Invalid argument supplied for foreach() in...', 'PHP Notice:  Undefined variable: ...']],
				[(_eq 'language','python'), error:["Fatal Python error: PyThreadState_Get: no current thread","[error] python_init: Python version mismatch, expected '2.7.2+', found '2.7.3'."]],
				[(_eq 'language','ruby'), error:['[BUG] Segmentation fault ruby 1.9.3p362 (2012-12-25 revision 38607) [x86_64-linux]']],
				[(_eq 'language','java'), error:['GRAVE: Could not compile the mapping document','java.lang.NullPointerException','java.lang.RuntimeException']],
				error:['hu ?','"could not find..."'],
				[0.1, uselib: 'w00t, no errors?']],
			error: [ "[Read|Understand] the error's description",
				[0.1, giveup:["not compatible with my framework.","maybe another lib"]],
				debuglib:['',"*ctrl+c*","let's fix it"]],

			# debug install
			debuglib: [
				readdoc:["the doc says...","*alt+tab*"]
				fixsources:[
					"what's there?","cd ./[src|lib]",
					((s)->"emacs [main|index]."+_exts[s.language]),
					"last function in callstack is...",
					(->"...line "+Math.floor(Math.random()*500+200)+":"+Math.floor(Math.random()*40+10))],
				stackoverflow:''
				[0.5, (_t 'fixsrc'), giveup:['i give up','have an idea.']],
				[(_t 'fixed'), uselib:'']],

			fixsources: [ "[Fix|Search error from] code in lib's sources",
				(_st 'fixsrc'),
				(_st 'fixed'),
				debuglib: ['','missing dependencies...',"it's just a warning"]],
			stackoverflow: ['Search error on [stackoverflow|the sdk\'s developer site|a {language} forum|the {language} official site]',
				(_st 'fixed'),
				[0.2,giveup:['another lib = less errors', '"Known issue"', '"not supported by [chrome|firefox|ie|opera|{language}]"']],
				debuglib:['not working...', 'I do the same !', 'version mismatch', 'ah, okay', "Let's try this fix"]],

			# use lib
			uselib: [
				(_sf 'fixsrc'),
				[(_f 'initlib'), initlib:''],
				[(_t 'initlib'), (_f 'requesttoken'), (_f 'oauth2'), requesttoken:'']
				[(_t 'initlib'), (_f 'authorize'), authorize:'']
			],
			initlib: [ 'Initialize lib',
				(_st 'installed')
				[(_f 'bugkeys'), debuglib: ((s)->s.bugkeys = true; '"[Missing|Invalid|Error with your] API key"')]
				[(_f 'bugobj'), debuglib: ((s)->s.bugobj = true; '"Could not [create|init] [Request|Auth] object"')]
				debuglib:['what is this Oo\'', 'it returns null!', 'uncaught exception']
				authorize:['', 'how should i get my token?', 'how does this work...', 'authorize!']
				requesttoken:['', 'how should i get my token?', 'how does this work...', 'request token!']
			],
			requesttoken: [ 'Request an unauthorized token',
				'Request /request_token',
				(_st 'initlib'),
				[(_f 'oauth1'),(_f 'oauth2'),(_st 'oauth2')]
				[(_f 'oauth1'),(_t 'oauth2'), authorize:((s)->s.oauth2 = true;'OAuth 2 don\'t need request token! LMAO!')]
				debuglib:['what is oauth_[nonce|callback|signature|signature_method]?', 'where do i make this request??', 'what, server side?'],
				authorize:((s)->s.requesttoken = true;'')
			],
			authorize: [ 'Direct user to service provider',
				'Request /authorize',
				'Redirect user to /authorize'
				(_st 'initlib'),
				[(_f 'oauth1'),(_f 'oauth2'),(_st 'oauth1')]
				[(_t 'oauth1'),(_f 'requesttoken'), requesttoken:((s)->s.oauth1 = true;'OAuth 1 needs a request token! ROFL!')]
				debuglib:[
					'"The request is missing a required parameter"...',
					'..."includes an unsupported parameter or parameter value"',
					'"The client identifier provided is invalid."',
					'"The client is not authorized to use the requested response type."',
					'"The redirection URI provided does not match a pre-registered value."',
					'"The end-user or authorization server denied the request."',
					'"The requested response type is not supported by the authorization server."',
					'"The requested scope is invalid, unknown, or malformed."',
					'click *[Okay|Authorize]*',
					'where is my [client_id|client_secret|app_id|consumer_id|consumer_secret|redirect_uri]',
					'scope elements are not separated by "[ |,|;]", i guess'
					'oauth_problem=signature_invalid'
				]
			]

		generatestep = (state) ->
			return state if state.deep == 0

			state.language ?= pickrandom Object.keys(_exts)
			state.node ?= nodes.start
			stepn = state.stepn
			state.res ?= []
			next = {}
			msgs = []
			farr = (arr) ->
				for elt in arr
					f = (elt) ->
						if elt == false
							return false
						else if Array.isArray(elt)
							farr elt
						else if typeof elt == "string"
							msgs.push elt
						else if typeof elt == "function"
							return f elt(state)
						else if elt instanceof Number || typeof elt == 'number'
							return false if elt < Math.random()
						else if typeof elt == "object"
							for nodename,nodemsg of elt
								next[nodename] = nodemsg
					if f(elt) == false
						break
			farr state.node

			greatreplace = (msg) ->
				msg = msg.replace /\[.+?\]/g, (x) ->
					x = x.substr(1,x.length-2)
					if x.indexOf('|') != -1
						return greatreplace pickrandom x.split '|'
					else
						return if Math.random() < 0.5 then x else ''
				msg = msg.replace /\*\*.+?\*\*/g, (x) ->
					x = x.substr(2,x.length-4)
					return '<span style="font-family:\'Courier New\'">' + x + "</span>"
				return msg.replace /\{.+?\}/g, (x) ->
					x = x.substr(1,x.length-2)
					return state[x] || x

			if msgs.length
				state.res.push stepn:state.stepn++, msg:(greatreplace pickrandom msgs)
				state.deep--

			nextnames = Object.keys(next)
			nextname = pickrandom nextnames
			if ! nextname?
				nextname = "start"
				comment = "FUUUUUuuu"
				console.log "unknown action from", state.node if debugmode
			else
				comment = next[nextname]
			if Array.isArray(comment)
				comment = pickrandom comment
			if typeof comment == "function"
				comment = comment(state)
			if comment
				state.res.push stepn:stepn, comment:(greatreplace comment)
			state.node = nodes[nextname]
			console.log 'unknown node name:', nextname if ! nodes[nextname] && debugmode
			return generatestep state

		return generatestep
	stubborn = stub()

	return stubborn