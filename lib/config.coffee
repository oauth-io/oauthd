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

Path = require 'path'
Url = require 'url'
config = require '../config'

if config.host_url[config.host_url.length-1] == '/'
	config.host_url = config.host_url.substr(0,config.host_url.length-1)
config.base = Path.normalize(config.base).replace `/\\/g`, '/'
config.relbase = config.base
config.base = '' if config.base == '/'
config.base_api = Path.normalize(config.base_api).replace `/\\/g`, '/'
config.url = Url.parse config.host_url

module.exports = config