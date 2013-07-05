"use strict";

var makeSetup = require("../common/makeSetup");
var grantToken = require("./grantToken");

var grantTypes = "password";
var reqPropertyName = "username";
var requiredHooks = ["validateClient", "grantUserToken", "authenticateToken"];

module.exports = makeSetup(grantTypes, reqPropertyName, requiredHooks, grantToken);
