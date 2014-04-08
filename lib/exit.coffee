# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

async = require 'async'

closing_stack = []
closing = false

# clean exit when possible
cleanExit = (killer) ->
	closing = true
	k = setTimeout (->
		console.error '--- FORCING STOP'
		process.kill process.pid
		return
	), 5000
	async.series closing_stack, (err, res) ->
		console.log '--- successfully closed !'
		setTimeout killer, 100
		return
	return

# nodemon restarting
process.once 'SIGUSR2', ->
	console.log '--- closing server...'
	cleanExit ->
		process.kill process.pid, 'SIGUSR2'
		return
	return

# uncaught exception catching
process.on 'uncaughtException', (err) ->
	if closing
		console.error '--- uncaughtException WHILE CLOSING'
	else
		console.error '--- uncaughtException'
	console.error err.stack.toString()
	console.error '--- node exiting now...'
	if closing
		process.exit 2
	else
		cleanExit ->
			process.exit 1
			return
	return

# push a closing function
exports.push = (name, f) ->
	closing_stack.push (callback) ->
		console.log 'Closing `' + name + '`...'
		f callback
		return
	return
