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

startTime = new Date

Path = require 'path'
config = require "./config"
async = require "async"
config.rootdir = Path.normalize __dirname + '/..'

# initialize plugins
exports.plugins = plugins = require "./plugins"
plugins.init()

# start server
exports.server = server = require './server'
async.series [
	plugins.data.db.providers.getList,
	server.listen
], (err) ->
	if err
		console.error 'Error while initialisation', err.message
		plugins.data.emit 'server', err
	else
		console.log 'Server is ready (load time: ' + Math.round(((new Date) - startTime) / 10) / 100 + 's)'