module.exports = (document) ->
	getAbsUrl: (url) ->
		return url  if url.match(/^.{2,5}:\/\//)
		return document.location.protocol + "//" + document.location.host + url  if url[0] is "/"
		base_url = document.location.protocol + "//" + document.location.host + document.location.pathname
		return base_url + "/" + url  if base_url[base_url.length - 1] isnt "/" and url[0] isnt "#"
		base_url + url

	replaceParam: (param, rep, rep2) ->
		param = param.replace(/\{\{(.*?)\}\}/g, (m, v) ->
			rep[v] or ""
		)
		if rep2
			param = param.replace(/\{(.*?)\}/g, (m, v) ->
				rep2[v] or ""
			)
		param
