### istanbul ignore next ###
module.exports =
	init: (config, document) ->
		@config = config
		@document = document
	createCookie: (name, value, expires) ->
			@eraseCookie name
			date = new Date()
			date.setTime date.getTime() + (expires or 1200) * 1000 # def: 20 mins
			expires = "; expires=" + date.toGMTString()
			@document.cookie = name + "=" + value + expires + "; path=/"
			return

	readCookie: (name) ->
		nameEQ = name + "="
		ca = @document.cookie.split(";")
		i = 0

		while i < ca.length
			c = ca[i]
			c = c.substring(1, c.length)  while c.charAt(0) is " "
			return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
			i++
		null

	eraseCookie: (name) ->
		date = new Date()
		date.setTime date.getTime() - 86400000
		@document.cookie = name + "=; expires=" + date.toGMTString() + "; path=/"
		return