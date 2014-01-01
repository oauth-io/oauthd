# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

request = require 'request'

exports.setup = (callback) ->

	if not @config.mailjet?.auth || not @config.mailjet.camp_id
		console.log 'Warning: mailjet plugin is not configured'
		return callback()

	mailjet = request.defaults auth: @config.mailjet.auth
	camp_id = @config.mailjet.camp_id

	@on 'user.register', (user) =>
		mailjet.post {
			url: 'https://api.mailjet.com/0.1/listsAddcontact'
			form:
				id:camp_id
				contact:user.mail
		}, (e,r,body) =>

	@server.get @config.base_api + '/adm/update_mailjet', @auth.adm, (req, res, next) =>
		@db.redis.hkeys 'u:mails', (err, mails) =>
			return next err if err
			mailjet.post {
				url: 'https://api.mailjet.com/0.1/listsAddmanycontacts'
				form:
					id:camp_id
					contacts:mails.join(',')
			}, (e,r,body) =>
				return next new @check.Error 'request error' if r.statusCode != 200 && r.statusCode != 304
				res.send @check.nullv
				next()

	callback()