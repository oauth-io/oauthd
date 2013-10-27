# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

Path = require 'path'
Url = require 'url'
config = require '../config'

config.base = Path.resolve '/', config.base
config.base = '' if config.base == '/'
config.base_api = Path.resolve '/', config.base_api
config.url = Url.parse config.host_url
config.bootTime = new Date

module.exports = config