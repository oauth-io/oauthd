# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

# to generate all providers from webshell, run
# find ~/fs/bin -name 'conf.json' | coffee prov_conv.coffee
#
# to test generation from facebook:
# echo ~/fs/bin/facebook/v0.1/conf.json | coffee prov_conv.coffee && cat providers/facebook.json

fs = require 'fs'

providerRegexp = /\/bin\/([^\/]+?)\/.*conf\.json$/

def =
	oauth2:
		authorize:
			url: "/authorize"
			query:
				client_id: "{client_id}"
				response_type: "code"
				redirect_uri: "{{callback}}"
				scope: "{scope}"
				state: "{{state}}"
		access_token:
			url: "/access_token"
			query:
				client_id: "{client_id}"
				client_secret: "{client_secret}"
				redirect_uri: "{{callback}}"
				grant_type: "authorization_code"
				code: "{{code}}"
		request:
			headers:
				"authorize":"Bearer {{token}}"

# longest common starting string
commonStr = (words) ->
	for i,ref of words[0]
		for word in words
			return words[0].substr(0, i) if ref != word[i]


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
	for endpoint_name in ["request_token", "authorize", "access_token"]
		endpoint = data.oauth2?[endpoint_name]
		if endpoint
			if endpoint.params?.redirect_uri == "{{callback}}?{{state}}"
				endpoint.params.redirect_uri = "{{callback}}"
				endpoint.params.state = "{{state}}" if endpoint_name == "authorize"
			useless_params = true
			for k,v of endpoint.params
				if v != def.oauth2[endpoint_name].query[k]
					useless_params = false
			endpoint.query = endpoint.params unless useless_params
			endpoint.params = undefined
			urls.push endpoint.url if endpoint.url

	delete data.oauth2?.access_token?.field
	delete data.oauth2?.access_token?.format

	request = data.oauth2?.request
	if request?
		delete request.format # assume its send a valid content-type
		if request.get? && Object.keys(request.get).length == 1 && request.get.oauth_token=="{{token}}"
			delete request.get
		if not Object.keys(request).length
			delete data.oauth2.request

	data.url = commonStr(urls).match(/^.*\//)[0]
	data.url = data.url.substr 0, data.url.length-1
	for oauthv in ["oauth1","oauth2"]
		for endpoint_name in ["request_token","authorize","access_token"]
			endpoint = data[oauthv]?[endpoint_name]
			if endpoint?.url
				endpoint.url = endpoint.url.substr(data.url.length)
				if endpoint.url == def[oauthv]?[endpoint_name]?.url
					delete data[oauthv][endpoint_name]
		if data[oauthv]?.parameters
			params = {}
			for param in data[oauthv].parameters
				pname = param.name
				delete param.name
				params[pname] = param
				if Object.keys(param).length == 1 && param.type
					params[pname] = param.type
			data[oauthv].parameters = params
		if data[oauthv]? && not Object.keys(data[oauthv]).length
			data[oauthv] = true

	# filter & reorder & return
	return {
		name:data.displayName
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
		data = reformat content
		try
			data = JSON.parse data
		catch e
			try
				JSON.parse content
			catch e
				return console.error "reformat broke", file, e
			return console.log "failed to parse", file, e
		data = rearrange data
		content = JSON.stringify data, null, "\t"
		fs.writeFile __dirname + '/providers/' + provider + '.json', content

process.stdin.resume()
process.stdin.on 'data', (buf) ->
	files = buf.toString().split "\n"
	for file in files
		translate file if file
