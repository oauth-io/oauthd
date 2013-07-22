"use strict";

var restify = require("restify");
var _ = require("underscore");

module.exports = function grantToken(req, res, next, options) {
    function sendOAuthError(errorClass, errorType, errorDescription) {
        var body = { error: errorType, error_description: errorDescription };
        var error = new restify[errorClass + "Error"]({ message: errorDescription, body: body });
        next(error);
    }

    function sendBadRequestError(type, description) {
        sendOAuthError("BadRequest", type, description);
    }

    function sendUnauthorizedError(description) {
        res.header("WWW-Authenticate", "Basic realm=\"" + description + "\"");
        sendOAuthError("Unauthorized", "invalid_client", description);
    }


    if (!req.body || typeof req.body !== "object") {
        return sendBadRequestError("invalid_request", "Must supply a body.");
    }

    if (!_.has(req.body, "grant_type")) {
        return sendBadRequestError("invalid_request", "Must specify grant_type field.");
    }

    if (req.body.grant_type !== "password") {
        return sendBadRequestError("unsupported_grant_type", "Only grant_type=password is supported.");
    }

    var username = req.body.username;
    var password = req.body.password;

    if (!username) {
        return sendBadRequestError("invalid_request", "Must specify username field.");
    }

    if (!password) {
        return sendBadRequestError("invalid_request", "Must specify password field.");
    }

    if (!req.authorization || !req.authorization.basic) {
        return sendBadRequestError("invalid_request", "Must include a basic access authentication header.");
    }

    var clientId = req.authorization.basic.username;
    var clientSecret = req.authorization.basic.password;

    options.hooks.validateClient(clientId, clientSecret, function (error, result) {
        if (error) {
            return next(error);
        }

        if (!result) {
            return sendUnauthorizedError("Client ID and secret did not validate.");
        }

        options.hooks.grantUserToken(username, password, function (error, token) {
            if (error) {
                return next(error);
            }

            if (!token) {
                return sendUnauthorizedError("Username and password did not authenticate.");
            }

            res.send({
                access_token: token,
                token_type: "Bearer",
                expires_in: options.tokenExpirationTime
            });
        });
    });
};
