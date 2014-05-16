# OAuth daemon
# Copyright (C) 2014 Webshell SAS
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


async = require 'async'
qs = require 'querystring'
Url = require 'url'
restify = require 'restify'
request = require 'request'
launch_testsuite = require './testsuite/tester'
Path = require 'path'

fs = require 'fs'
shared = require '../shared'

files = fs.readdirSync Path.join(__dirname, 'testsuite', 'caspertests', 'providers')
providers = []
for k of files
	providers.push files[k].replace '.coffee', ''


run_tests = (providers, k) ->
	k = k || 0
	if (k < providers.length)
		launch_testsuite(providers[k])
		.then (data) ->
			test_passed = data.passed
			result = data.messages
			if (not test_passed)
				shared.emit 'provider_testing.failure', providers[k], result
			run_tests providers, k + 1

exports.raw = ->
	run_tests providers
	setInterval (->
		run_tests providers
	), 1800000