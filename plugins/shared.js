/*
OAuth daemon
Copyright (C) 2013 Webshell SAS

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
 any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

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