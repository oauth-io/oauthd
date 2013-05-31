// oauthd
// http://oauth.io
//
// Copyright (c) 2013 thyb, bump
// Licensed under the MIT license.

// The purpose of this file to share data between plugins
// by using the require's cache behaviour:
//
// shared = require([this file])
// shared.xy = 123
//
// This will make xy usable from other files
// The object is an EventEmitter so that it can share events

var events = require('events');
module.exports = new events.EventEmitter();