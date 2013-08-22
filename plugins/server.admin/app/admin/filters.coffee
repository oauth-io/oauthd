# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
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

hooks.config.push ->
	app.filter 'toUpper', ->
		return (input, scope) ->
			if input
				return input.toUpperCase()

	app.filter 'trunc', ->
		return (input, chars) ->
			return input if isNaN(chars)
			return '' if chars <= 0
			if input && input.length >= chars
				return input.substring(0, chars).trim() + '...'
			return input

	app.filter 'capitalize', -> (input, scope) ->
		return input if not input
		str = ''
		arr = input.split '_'
		for i in arr
			str += i.substring(0,1).toUpperCase() + i.substring(1) + ' '
		return str.substring 0, str.length - 1

	app.filter 'startFrom', -> (input, start) ->
		return [] if not input
		start = +start
		return input.slice(start)
