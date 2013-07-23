"use strict";

function hasBearerToken(req) {
    return req.authorization && req.authorization.scheme === "Bearer" && req.authorization.credentials.length > 0;
}

function getBearerToken(req) {
    return hasBearerToken(req) ? req.authorization.credentials : null;
}

module.exports = function makeHandleAuthenticatedResource(reqPropertyName, errorSenders) {
    return function handleAuthenticatedResource(req, res, next, options) {
        var token = getBearerToken(req);
        if (!token) {
            return errorSenders.tokenRequired(res, options);
        }

        req.pause();
        options.hooks.authenticateToken(token, function (error, credential) {
            req.resume();

            if (error) {
                return errorSenders.sendWithHeaders(res, options, error);
            }

            if (!credential) {
                return errorSenders.tokenInvalid(res, options);
            }

            req[reqPropertyName] = credential;
            next();
        });
    };
};
