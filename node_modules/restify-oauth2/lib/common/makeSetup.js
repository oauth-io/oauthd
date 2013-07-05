"use strict";

var _ = require("underscore");

module.exports = function makeSetup(grantTypes, reqPropertyName, requiredHooks, grantToken) {
    var errorSenders = require("./makeErrorSenders")(grantTypes);
    var handleAuthenticatedResource = require("./makeHandleAuthenticatedResource")(reqPropertyName, errorSenders);

    return function restifyOAuth2Setup(server, options) {
        if (typeof options.hooks !== "object" || options.hooks === null) {
            throw new Error("Must supply hooks.");
        }
        requiredHooks.forEach(function (hookName) {
            if (typeof options.hooks[hookName] !== "function") {
                throw new Error("Must supply " + hookName + " hook.");
            }
        });

        options = _.defaults(options, {
            tokenEndpoint: "/token",
            wwwAuthenticateRealm: "Who goes there?",
            tokenExpirationTime: Infinity
        });

        // Allow `tokenExpirationTime: Infinity` (like above), but translate it into `undefined` so that `JSON.stringify`
        // omits it entirely when we write out the response as `JSON.stringify({ expires_in: tokenExpirationTime, ... })`.
        if (options.tokenExpirationTime === Infinity) {
            options.tokenExpirationTime = undefined;
        }

        server.post(options.tokenEndpoint, function (req, res, next) {
            grantToken(req, res, next, options);
        });

        server.use(function ccOAuth2Plugin(req, res, next) {
            res.sendUnauthorized = function (message) {
                errorSenders.authorizationRequired(res, options, message);
            };

            if (req.method === "POST" && req.path() === options.tokenEndpoint) {
                // This is handled by the route installed above, so do nothing.
                next();
            } else if (req.authorization.scheme) {
                handleAuthenticatedResource(req, res, next, options);
            } else {
                req.username = null;
                next();
            }
        });
    };
};
