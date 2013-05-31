# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

Path = require 'path'
config = require '../config'

config.base = Path.resolve '/', config.base
config.base = '' if config.base = '/'

module.exports = config