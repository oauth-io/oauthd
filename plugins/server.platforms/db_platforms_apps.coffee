# oauth
# http://oauth.io/
#
# Copyright (c) 2014 Webshell
# For private use only.

restify = require 'restify'
{config,check,db} = shared = require '../shared'

#### APPS

exports.create = (data, admin, callback) ->

exports.getDetails = (key, data, admin, callback) ->

exports.update = (key, data, admin, callback) ->

exports.remove = (key, data, admin, callback) ->

exports.resetKeys = (key, data, admin, callback) ->


#### DOMAINS

exports.listDomain = (key, data, admin, callback) ->


exports.updateDomains = (key, data, admin, callback) ->


exports.addDomain = (key, domain, data, admin, callback) ->


exports.removeDomain = (key, domain, data, admin, callback) ->



#### KEYSETS

exports.getKeysets = (key, data, admin, callback) ->


exports.getKeyset = (key, provider, data, admin, callback) ->


exports.addKeyset = (key, provider, data, admin, callback) ->


exports.removeKeyset = (key, provider, data, admin, callback) ->



