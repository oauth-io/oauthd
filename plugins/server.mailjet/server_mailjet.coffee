# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

request = require 'request'

mailjet = request.defaults {
	auth:
		user: 'xxxxxxxxxxxxxxxxxxxxx'
		pass: 'yyyyyyyyyyyyyyyyyyyyy'
}

camp_id = 'zzzzz'

exports.setup = (callback) ->

	@on 'user.register', (user) =>
		mailjet.post {
			url: 'https://api.mailjet.com/0.1/listsAddcontact'
			form:
				id:camp_id
				contact:user.mail
		}, (e,r,body) =>

	@server.get @config.base + '/api/adm/update_mailjet', @auth.adm, (req, res, next) =>
		@db.redis.hkeys 'u:mails', (err, mails) =>
			return next err if err
			mailjet.post {
				url: 'https://api.mailjet.com/0.1/listsAddmanycontacts'
				form:
					id:camp_id
					contacts:mails.join(',')
			}, (e,r,body) =>
				console.log(body, r);
				return next new @check.Error 'request error' if r.statusCode != 200 && r.statusCode != 304
				res.send @check.nullv
				next()

	callback()