"use strict";

var makeSetup = require("../common/makeSetup");
var grantToken = require("./grantToken");

var grantTypes = "client_credentials";
var reqPropertyName = "clientId";
var requiredHooks = ["grantClientToken", "authenticateToken"];

module.exports = makeSetup(grantTypes, reqPropertyName, requiredHooks, grantToken);
