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

fs = require 'fs'

module.exports = (env) ->
	config = env.config

	sdk_js_str = null
	sdk_js_str_min = null

	return {
		get: (callback) ->
			return callback null, sdk_js_str if sdk_js_str
			fs.readFile __dirname + '/js_sdk/oauth.js', 'utf8', (err, data) ->
				sdk_js_str = data
				callback null, sdk_js_str,
		getmin: (callback) ->
			return callback null, sdk_js_str_min if sdk_js_str_min
			fs.readFile __dirname + '/js_sdk/oauth.min.js', 'utf8', (err, data) ->
				sdk_js_str_min = data
				callback null, sdk_js_str_min
	}