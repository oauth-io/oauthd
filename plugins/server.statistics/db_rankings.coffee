# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

{check,db} = shared = require '../shared'

exports.getTotal = check 'string', (target, callback) ->
	db.redis.multi([
		['zcount', 'sr:' + target, '-inf', '+inf']
		['get', 'sr:' + target + ':t'],
	]).exec callback

exports.getRanking = check 'string', start:['int','none'], end:['int','none'], (target, data, callback) ->
	{start,end} = data
	start ?= 0
	end ?= -1
	db.redis.zrevrange 'sr:' + target, start, end, "withscores", (e, r) ->
		return callback e if e
		res = ({name:r[k], score:parseInt(r[k+1])} for k in [0..r.length-1] by 2)
		callback null, res

exports.addScore = check 'string', id:'string', val:['number','none'], (target, data, callback) ->
	val = data.val || 1
	db.redis.multi([
		['zincrby', 'sr:' + target, val, data.id]
		['incrby', 'sr:' + target + ':t', val]
	]).exec callback

exports.setScore = check 'string', id:'string', val:'number', (target, data, callback) ->
	db.redis.multi([
		['zadd', 'sr:' + target, data.val, data.id]
		['set', 'sr:' + target + ':t', data.val]
	]).exec callback

db.rankings = exports