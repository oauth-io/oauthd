# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

# to generate all providers from webshell (and show only errors), run
# find ~/fs/bin -name 'conf.json' | coffee prov_conv.coffee > /dev/null
#
# to test generation from facebook:
# echo ~/fs/bin/facebook/v0.1/conf.json | coffee prov_conv.coffee && cat providers/facebook.json
#

fs = require 'fs'
Url = require 'url'

providerRegexp = /.*\/bin\/([^\/]+?)\/.*conf\.json$/

def =
	oauth2:
		authorize:
#			url: "/authorize"
			query:
				client_id: "{client_id}"
				response_type: "code"
				redirect_uri: "{{callback}}"
				scope: "{scope}"
				state: "{{state}}"
		access_token:
#			url: "/access_token"
			query:
				client_id: "{client_id}"
				client_secret: "{client_secret}"
				redirect_uri: "{{callback}}"
				grant_type: "authorization_code"
				code: "{{code}}"
#		request:
#			headers:
#				"authorize":"Bearer {{token}}"
	oauth1:
		request_token:
#			url: "/request_token"
			query:
				oauth_consumer_key: "{client_id}"
				oauth_callback: "{{callback}}"
		authorize: {}
#			url: "/authorize"
#			query:
		access_token:
#			url: "/access_token"
			query:
				oauth_consumer_key: "{client_id}"
#		request:

# longest common starting string
commonStr = (words) ->
	for i,ref of words[0]
		for word in words
			return words[0].substring(0, i) if ref != word[i]
	return words[0]

# preprocess json
reformat = (data) ->
	data = data.replace /\{_callback_args\}/g, '{{state}}'
	data = data.replace /\{_callback_url\}/g, '{{callback}}'
	data = data.replace /\{_code\}/g, '{{code}}'
	data = data.replace /\{_access_token\}/g, '{{token}}'
	return data

# transform object
rearrange = (data) ->
	urls = []
	[data.oauth1, data.oauth2] = auths = [data.auth.oauth1, data.auth.oauth2]
	for oauthv in ["oauth1","oauth2"]
		for endpoint_name in ["request_token", "authorize", "access_token"]
			endpoint = data[oauthv]?[endpoint_name]
			if endpoint
				if oauthv == 'oauth2' && endpoint.params?.redirect_uri == "{{callback}}?{{state}}"
					endpoint.params.redirect_uri = "{{callback}}"
					#don't add state: add it by def if not in params (state is mandatory anyway)
					#endpoint.params.state = "{{state}}" if endpoint_name == "authorize"
				if oauthv == 'oauth1' && endpoint.params?.oauth_callback == "{{callback}}?{{state}}"
					endpoint.params.oauth_callback = "{{callback}}"
				useless_params = true
				for k,v of endpoint.params
					if v != def[oauthv][endpoint_name].query?[k]
						useless_params = false
				endpoint.query = endpoint.params unless useless_params
				delete endpoint.params
				urls.push endpoint.url if endpoint.url

	delete data.oauth2?.access_token?.field
	delete data.oauth2?.access_token?.format

	return false if not urls.length
	data.url = commonStr(urls).match(/^.*\//)
	return "Could not determine common url" if not data.url
	data.url = data.url[0]
	data.url = data.url.substr 0, data.url.length-1
	for oauthv in ["oauth1","oauth2"]
		request = data[oauthv]?.request
		if request?
			delete request.format # assume its send a valid content-type
			if request.params
				request.query = request.params
			if request.get
				request.query = request.get
			delete request.params
			delete request.get
			### # no default request for oauth2, kikoo-provider-oriented
			if oauthv == 'oauth2' &&
				request.get? &&
				Object.keys(request.get).length == 1 &&
				request.get.oauth_token=="{{token}}"
					delete request.get
			###
			if oauthv == 'oauth1' &&
				request.query? &&
				Object.keys(request.query).length == 1 &&
				request.query.oauth_consumer_key=="{client_id}"
					delete request.query
			if not Object.keys(request).length
				delete data[oauthv].request

		for endpoint_name in ["request_token","authorize","access_token"]
			endpoint = data[oauthv]?[endpoint_name]
			if endpoint?.url
				endpoint.url = endpoint.url.substr(data.url.length)
				if Object.keys(endpoint).length == 1 && endpoint.url
					data[oauthv][endpoint_name] = endpoint.url
		if data[oauthv]?.parameters
			params = {}
			for param in data[oauthv].parameters
				pname = param.name
				delete param.name
				params[pname] = param
				if Object.keys(param).length == 1 && param.type
					params[pname] = param.type
			data[oauthv].parameters = params
#		oauth[12] cannot be empty :/
#		if data[oauthv]? && not Object.keys(data[oauthv]).length
#			data[oauthv] = true

	if data.parameters
		params = {}
		for param in data.parameters
			pname = param.name
			delete param.name
			params[pname] = param
			if Object.keys(param).length == 1 && param.type
				params[pname] = param.type
		data.parameters = params

	delete data.base_url if not data.base_url
	if data.base_url
		url1 = Url.parse(data.url)
		url2 = Url.parse(data.base_url)
		if url1.protocol != url2.protocol || url1.host != url2.host
			data.api_url = data.base_url

	# filter & reorder & return
	return {
		name:data.displayName
		api_url:data.api_url
		url:data.url
		oauth2:data.oauth2
		oauth1:data.oauth1
		parameters:data.parameters
	}

translate = (file) ->
	provider = providerRegexp.exec file
	if not provider
		return console.error "failed to translate", file
	provider = provider[1]
	content = fs.readFile file, 'utf8', (err, content) ->
		console.log "\nTranslating " + provider + "..."
		try
			data = reformat content
		catch e
			return console.error "could not reformat", file, e.stack
		try
			data = JSON.parse data
		catch e
			try
				JSON.parse content
			catch e
				return console.log "failed to parse", file, e # not my fault
			return console.error "reformat broke", file, e
		try
			data = rearrange data
		catch e
			return console.error "could not rearrange", file, e.stack
		if typeof data == 'string'
			return console.error data, file
		if not data
			return console.log "this conf has not oauth", file
		content = JSON.stringify data, null, "\t"
		console.log "Translated!"
		fs.writeFile __dirname + '/providers/' + provider + '.json', content

buff = ''
process.stdin.resume()
process.stdin.on 'end', ->
	translate buff if buff
process.stdin.on 'data', (buf) ->
	buff += buf.toString()
	files = buff.split "\n"
	buff = files.pop()
	for file in files
		translate file if file
