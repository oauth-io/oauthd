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

styles =
	# styles
	'bold'      : ['\x1B[1m',  '\x1B[22m'],
	'italic'    : ['\x1B[3m',  '\x1B[23m'],
	'underline' : ['\x1B[4m',  '\x1B[24m'],
	'inverse'   : ['\x1B[7m',  '\x1B[27m'],
	'strikethrough' : ['\x1B[9m',  '\x1B[29m'],
	# text colors
	# grayscale
	'white'     : ['\x1B[37m', '\x1B[39m'],
	'grey'      : ['\x1B[90m', '\x1B[39m'],
	'black'     : ['\x1B[30m', '\x1B[39m'],
	# colors
	'blue'      : ['\x1B[34m', '\x1B[39m'],
	'cyan'      : ['\x1B[36m', '\x1B[39m'],
	'green'     : ['\x1B[32m', '\x1B[39m'],
	'magenta'   : ['\x1B[35m', '\x1B[39m'],
	'red'       : ['\x1B[31m', '\x1B[39m'],
	'yellow'    : ['\x1B[33m', '\x1B[39m'],
	# background colors
	# grayscale
	'whiteBG'     : ['\x1B[47m', '\x1B[49m'],
	'greyBG'      : ['\x1B[49;5;8m', '\x1B[49m'],
	'blackBG'     : ['\x1B[40m', '\x1B[49m'],
	# colors
	'blueBG'      : ['\x1B[44m', '\x1B[49m'],
	'cyanBG'      : ['\x1B[46m', '\x1B[49m'],
	'greenBG'     : ['\x1B[42m', '\x1B[49m'],
	'magentaBG'   : ['\x1B[45m', '\x1B[49m'],
	'redBG'       : ['\x1B[41m', '\x1B[49m'],
	'yellowBG'    : ['\x1B[43m', '\x1B[49m']

styles.wrap = (st, msg) ->
	st = [st] if not Array.isArray(st)
	res = ""
	res += styles[s][0] for s in st
	res += msg
	res += styles[s][1] for s in st
	return res

module.exports = styles