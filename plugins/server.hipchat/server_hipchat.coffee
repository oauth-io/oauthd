# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.
#

request = require 'request'

exit = require '../../lib/exit'

exports.setup = (callback) ->

	if not @config.hipchat?.token
		console.log 'Warning: hipchat plugin is not configured'
		return callback()
	else
		console.log 'hipchat plugin token : ' + @config.hipchat.token

	hipchat = (data, cb) =>
		request {
			url: 'https://api.hipchat.com/v1/rooms/message'
			method: 'POST'
			qs:
				auth_token: @config.hipchat.token
			form:
				room_id: data.room
				from: data.from || @config.hipchat.name
				message: data.message.replace(/\n/g,'<br/>')
				message_format: 'html'
				notify: '1'
				color: data.color || 'yellow'
		}, (e, r, body) ->
			cb() if cb

	@on 'user.contact', (data) =>
		hipchat room:@config.hipchat.room_support, message:data.body

	@on 'user.pay', (data) =>
		msg = data.user.profile.name + ' bought (or recurring) offer ' + data.user.plan.displayName
		msg += '( $' + (data.invoice.total / 100) + ' )'
		msg += ' *shlingggggggggggg*' if data.invoice.total > 0
		hipchat room:@config.hipchat.room_activities, message: msg

	@on 'user.pay.failed', (data) =>
		msg = data.user.profile.name + '[' + data.user.profile.id + ']'
		msg += ' (' + data.customer.email + ') has failed to pay his invoice ( $' + (data.invoice.total / 100) + ' ) :('
		hipchat room:@config.hipchat.room_support, message: msg

	@on 'heroku_user.subscribe', (heroku_user, offer) =>
		msg = heroku_user.mail + '[' + heroku_user.id + ']'
		msg += 'subscribe to heroku oauthio addon with plan ' + offer + '.'
		hipchat room:@config.hipchat.room_activities, message: msg
		
	@on 'heroku_user.unsubscribe', (heroku_user) =>
		msg = heroku_user.mail + '[' + heroku_user.id + ']'
		msg += ' unsubscribe from heroku oauthio addon.'
		hipchat room:@config.hipchat.room_activities, message: msg

	@on 'provider_testing.failure', (provider, messages) =>
		msg = 'Tests on provider "' + provider + '" failed on the following step(s) :' + "\n" + messages.join("\n")
		hipchat room:@config.hipchat.room_activities, message: msg, color: 'red', from: 'Provider tester'

	if @config.hipchat.crash_monitor
		exit.push 'crash monitor', (callback) =>
			return callback() if not exit.err
			msg = '--- uncaughtException ' + (new Date).toGMTString() + "\n"
			msg += exit.err.stack.toString()
			msg += "\n---"
			hipchat room:@config.hipchat.room_support, message:msg, callback

	callback()