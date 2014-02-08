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

config = require './config'

sdk_js_str = null
sdk_js_str_min = null

exports.get = (callback) ->
	return callback null, sdk_js_str if sdk_js_str
	fs.readFile config.rootdir + '/app/js/oauth.js', 'utf8', (err, data) ->
		sdk_js_str = data.replace /\{\{auth_url\}\}/g, config.host_url + config.base
		sdk_js_str = sdk_js_str.replace /\{\{api_url\}\}/g, config.base_api
		callback null, sdk_js_str

exports.getmin = (callback) ->
	return callback null, sdk_js_str_min if sdk_js_str_min
	fs.readFile config.rootdir + '/app/js/oauth.min.js', 'utf8', (err, data) ->
		sdk_js_str_min = data.replace /\{\{auth_url\}\}/g, config.host_url + config.base
		sdk_js_str_min = sdk_js_str_min.replace /\{\{api_url\}\}/g, config.base_api
		callback null, sdk_js_str_min