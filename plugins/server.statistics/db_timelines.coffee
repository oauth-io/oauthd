# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

{check,db} = shared = require '../shared'

dateFormat = (date, format) ->
	format = format.replace "DD", (if date.getUTCDate() < 10 then '0' else '') + date.getUTCDate()
	format = format.replace "MM", (if date.getUTCMonth() < 9 then '0' else '') + (date.getUTCMonth() + 1)
	format = format.replace "HH", (if date.getUTCHours() < 10 then '0' else '') + date.getUTCHours()
	format = format.replace "YYYY", date.getUTCFullYear()
	return format

exports.getTotal = check 'string', (target, callback) ->
	db.redis.get 'st:' + target + ':t', (err, total) ->
		return callback err if err
		callback null, total

exports.getTimeline = check 'string', unit:'string', start:'int', end:'int', (target, data, callback) ->
	unit = data.unit || 'm'
	keys = {}
	date = new Date (data.start * 1000)
	dateEnd = new Date (data.end * 1000)

	if unit == 'm'
		loop
			year = date.getFullYear()
			month = date.getMonth()
			keys['st:' + target + ':m:' + year + '-' + (month + 1)] = dateFormat date, 'YYYY-MM'
			date = new Date(year, month + 1, 2) # second day, to keep utc safe
			break unless (date <= dateEnd || date.getMonth() == dateEnd.getMonth())
	else if unit == 'd'
		loop
			year = date.getFullYear()
			month = date.getMonth()
			day = date.getDate()
			keys['st:' + target + ':d:' + year + '-' + (month + 1) + '-' + day] = dateFormat date, 'YYYY-MM-DD'
			date = new Date(year, month, day + 1, 12) # add 12h to keep utc safe
			break unless (date <= dateEnd || date.getDate() == dateEnd.getDate())
	else if unit = 'h'
		loop
			year = date.getFullYear()
			month = date.getMonth()
			day = date.getDate()
			hours = date.getHours()
			keys['st:' + target + ':h:' + year + '-' + (month + 1) + '-' + day + '-' + hours] = dateFormat date, 'YYYY-MM-DD HH:00'
			date = new Date(year, month, day, hours + 1)
			break unless (date <= dateEnd)

	db.redis.mget Object.keys(keys), (err, res) ->
		return callback err if err
		result = {}
		for k,v of keys
			val = res.shift()
			if val
				result[v] = parseInt(val)
			else
				result[v] = 0
		callback null, result

exports.addUse = check target:'string', uses:['number','none'], (data, callback) ->
	date = new Date
	month = date.getFullYear() + "-" + (date.getMonth() + 1)
	day = month + "-" + date.getDate()
	hours = day + "-" + date.getHours()
	uses = data.uses || 1
	target = data.target
	rediscmds = [
		['incrby', 'st:' + target + ':m:' + month, uses]
		['incrby', 'st:' + target + ':d:' + day, uses]
		['incrby', 'st:' + target + ':h:' + hours, uses]
		['incrby', 'st:' + target + ':t', uses]
	]
	(db.redis.multi rediscmds).exec callback

db.timelines = exports