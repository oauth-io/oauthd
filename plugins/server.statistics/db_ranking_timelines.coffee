# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

{check,db} = shared = require '../shared'

getWeek = ($y,$m,$d) ->
	if ($m <= 2)
		a = $y - 1
		b = (a / 4 | 0) - (a / 100 | 0) + (a / 400 | 0)
		c = ((a - 1) / 4 | 0) - ((a - 1) / 100 | 0) + ((a - 1) / 400 | 0)
		s = b - c
		e = 0
		f = $d - 1 + (31 * ($m - 1))
	else
		a = $y
		b = (a / 4 | 0) - (a / 100 | 0) + (a / 400 | 0)
		c = ((a - 1) / 4 | 0) - ((a - 1) / 100 | 0) + ((a - 1) / 400 | 0)
		s = b - c
		e = s + 1
		f = $d + ((153 * ($m - 3) + 2) / 5) + 58 + s

	g = (a + b) % 7
	d = (f + g - e) % 7
	n = (f + 3 - d) | 0

	if (n < 0)
		w = 53 - ((g - s) / 5 | 0)
	else if (n > 364 + s)
		w = 1
	else
		w = (n / 7 | 0) + 1

	return w

dateFormat = (date, format) ->
	format = format.replace "DD", (if date.getUTCDate() < 10 then '0' else '') + date.getUTCDate()
	format = format.replace "MM", (if date.getUTCMonth() < 9 then '0' else '') + (date.getUTCMonth() + 1)
	format = format.replace "HH", (if date.getUTCHours() < 10 then '0' else '') + date.getUTCHours()
	format = format.replace "YYYY", date.getUTCFullYear()
	return format

exports.getTotal = check 'string', unit:['string','none'], timestamp:['int','none'], (target, data, callback) ->
	if data.unit
		if data.timestamp
			date = new Date(data.timestamp * 1000)
		else
			date = new Date()
		year = date.getFullYear()
		month = date.getMonth() + 1
		day = date.getDate()
		if data.unit == 'm'
			target += ':m:' + year + '-' + month
		else if data.unit == 'w'
			target += ':w:' + year + '-' + getWeek(year,month,day)
		else if data.unit == 'd'
			target += ':d:' + year + '-' + month + '-' + day
	db.rankings.getTotal target, callback

exports.getRanking = check 'string', unit:['string','none'], timestamp:['int','none']
	, start:['int','none'], end:['int','none'], (target, data, callback) ->
		if data.unit
			if data.timestamp
				date = new Date(data.timestamp * 1000)
			else
				date = new Date()
			year = date.getFullYear()
			month = date.getMonth() + 1
			day = date.getDate()
			if data.unit == 'm'
				target += ':m:' + year + '-' + month
			else if data.unit == 'w'
				target += ':w:' + year + '-' + getWeek(year,month,day)
			else if data.unit == 'd'
				target += ':d:' + year + '-' + month + '-' + day
		db.rankings.getRanking target, data, callback

exports.addScore = check 'string', id:'string', val:['number','none']
	, timestamp:['int','none'], (target, data, callback) ->
		if data.timestamp
			date = new Date(data.timestamp * 1000)
		else
			date = new Date()
		year = date.getFullYear()
		month = date.getMonth() + 1
		day = date.getDate()

		week = year + '-' + getWeek(year,month,day)
		month = year + "-" + month
		day = month + "-" + day
		val = data.val || 1
		db.redis.multi([
			['incrby', 'sr:' + target + ':m:' + month + ':t', val]
			['zincrby', 'sr:' + target + ':m:' + month, val, data.id]
			['incrby', 'sr:' + target + ':w:' + week + ':t', val]
			['zincrby', 'sr:' + target + ':w:' + week, val, data.id]
			['incrby', 'sr:' + target + ':d:' + day + ':t', val]
			['zincrby', 'sr:' + target + ':d:' + day, val, data.id]
			['incrby', 'sr:' + target + ':t', val]
			['zincrby', 'sr:' + target, val, data.id]
		]).exec callback

db.ranking_timelines = exports