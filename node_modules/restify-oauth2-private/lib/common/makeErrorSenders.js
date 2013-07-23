"use strict";

var restify = require("restify");

var statusCodesToErrorCodes = {
    400: "invalid_request",
    401: "invalid_token"
};

module.exports = function makeErrorSenders(grantTypes) {
    function setLinkHeader(res, options) {
        res.header("Link",
            "<" + options.tokenEndpoint + ">; rel=\"oauth2-token\"; " +
            "grant-types=\"" + grantTypes + "\"; token-types=\"bearer\"");
    }

    function setWwwAuthenticateHeader(res, options, error) {
        res.header("WWW-Authenticate",
            "Bearer realm=\"" + options.wwwAuthenticateRealm + "\", " +
            "error=\"" + statusCodesToErrorCodes[error.statusCode] + "\", " +
            "error_description=\"" + error.message + "\"");
    }

    function setWwwAuthenticateHeaderWithoutErrorInfo(res, options) {
        // See http://tools.ietf.org/html/rfc6750#section-3.1: "If the request lacks any authentication information
        // (e.g., the client was unaware that authentication is necessary or attempted using an unsupported
        // authentication method), the resource server SHOULD NOT include an error code or other error information."
        res.header("WWW-Authenticate", "Bearer realm=\"" + options.wwwAuthenticateRealm + "\"");
    }

    function sendWithHeaders(res, options, error) {
        if (error.statusCode in statusCodesToErrorCodes) {
            setLinkHeader(res, options);
            setWwwAuthenticateHeader(res, options, error);
        }
        res.send(error);
    }

    function sendAuthorizationRequired(res, options, error) {
        setLinkHeader(res, options);
        setWwwAuthenticateHeaderWithoutErrorInfo(res, options);
        res.send(error);
    }

    return {
        sendWithHeaders: sendWithHeaders,

        tokenRequired: function (res, options, message) {
            if (message === undefined) {
                message = "Bearer token required. Follow the oauth2-token link to get one!";
            }

            sendWithHeaders(res, options, new restify.BadRequestError(message));
        },

        authorizationRequired: function (res, options, message) {
            if (message === undefined) {
                message = "Authorization via bearer token required. Follow the oauth2-token link to get one!";
            }

            sendAuthorizationRequired(res, options, new restify.UnauthorizedError(message));
        },

        tokenInvalid: function (res, options, message) {
            if (message === undefined) {
                message = "Bearer token invalid. Follow the oauth2-token link to get a valid one!";
            }

            sendWithHeaders(res, options, new restify.UnauthorizedError(message));
        }
    };
};
