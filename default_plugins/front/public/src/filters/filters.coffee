module.exports = (app) ->
	app.filter 'capitalize', () ->
		(str) ->
			return "" if not str || not str[0]
			return str[0].toUpperCase() + str.substr 1
	app.filter 'minimize_key', () ->
		(str) ->
			return str.substr(0, 5) + '...' + str.substr(str.length - 4, str.length - 1)

	app.filter 'count', () ->
		(object) ->
			count = 0
			for k,v of object
				count++
			return count