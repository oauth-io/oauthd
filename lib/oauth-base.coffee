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

dbstates = require './db_states'
db = require './db'

class OAuthBase
	constructor: (oauthv) ->
		@_params = {}
		@_oauthv = oauthv
		@_short_formats = json: 'application/json', url: 'application/x-www-form-urlencoded'

	_setParams: (parameters) ->
		@_params[k] = v for k,v of parameters
		return

	_replaceParam: (param, hard_params, keyset) ->
		param = param.replace /\{\{(.*?)\}\}/g, (match, val) ->
			return db.generateUid() if val == "nonce"
			return hard_params[val] || ""
		return param.replace /\{(.*?)\}/g, (match, val) =>
			return "" if ! @_params[val] || ! keyset[val]
			if Array.isArray(keyset[val])
				return keyset[val].join @_params[val].separator || ","
			return keyset[val]

	_createState: (provider, opts, callback) ->
		newStateData =
			key: opts.key,
			provider: provider.provider,
			redirect_uri: opts.redirect_uri,
			oauthv: @_oauthv,
			origin: opts.origin,
			options: opts.options,
			expire: 1200
		dbstates.add newStateData, callback

module.exports = OAuthBase