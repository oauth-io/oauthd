"use strict";

var sha1 = require('./tools/sha1');
var config = require('./config');
var datastore = require('./tools/datastore')(config);
var Url = require('./tools/url')();

var oauthio = {
    request: {}
};

var providers_desc = {};
var providers_cb = {};
var providers_api = {
    "execProvidersCb": function(provider, e, r) {
        if (providers_cb[provider]) {
            var cbs = providers_cb[provider];
            delete providers_cb[provider];
            for (var i in cbs) cbs[i](e, r);
        }
    },
    // "fetchDescription": function(provider) is created once jquery loaded
    "getDescription": function(provider, opts, callback) {
        opts = opts || {};
        if (typeof providers_desc[provider] === 'object') return callback(null, providers_desc[provider]);
        if (!providers_desc[provider]) providers_api.fetchDescription(provider);
        if (!opts.wait) return callback(null, {});
        providers_cb[provider] = providers_cb[provider] || [];
        providers_cb[provider].push(callback);
    }
};

config.oauthd_base = Url.getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];

var client_states = [];
var oauth_result;
(function parse_urlfragment() {
    var results = /[\\#&]oauthio=([^&]*)/.exec(document.location.hash);
    if (results) {
        document.location.hash = document.location.hash.replace(/&?oauthio=[^&]*/, '');
        oauth_result = decodeURIComponent(results[1].replace(/\+/g, " "));
        var cookie_state = datastore.cookies.readCookie("oauthio_state");
        if (cookie_state) {
            client_states.push(cookie_state);
            datastore.cookies.eraseCookie("oauthio_state");
        }
    }
})();

module.exports = function(exports) {
    if (!exports.OAuth) {
        exports.OAuth = {
            initialize: function(public_key, options) {
                config.key = public_key;
                if (options)
                    for (var i in options) config.options[i] = options[i];
            },
            setOAuthdURL: function(url) {
                config.oauthd_url = url;
                config.oauthd_base = Url.getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];
            },
            getVersion: function() {
                return config.version;
            },
            create: function(provider, tokens, request) {
                if (!tokens) return datastore.cache.tryCache(provider, true);
                if (typeof request !== 'object') providers_api.fetchDescription(provider);
                var make_res = function(method) {
                    return oauthio.request.mkHttp(provider, tokens, request, method);
                }
                var make_res_endpoint = function(method, url) {
                    return oauthio.request.mkHttpEndpoint(data.provider, tokens, request, method, url);
                }
                var res = {};
                for (var i in tokens) res[i] = tokens[i];
                res.get = make_res('GET');
                res.post = make_res('POST');
                res.put = make_res('PUT');
                res.patch = make_res('PATCH');
                res.del = make_res('DELETE');

                res.me = function(opts) {
                    oauthio.request.mkHttpMe(data.provider, tokens, request, 'GET');
                }
                return res;
            },
            popup: function(provider, opts, callback) {
                var wnd, frm, wndTimeout;
                var defer = $.Deferred();
                opts = opts || {};
                if (!config.key) {
                    defer.rejet(new Error('OAuth object must be initialized'));
                    return callback(new Error('OAuth object must be initialized'));
                }
                if (arguments.length == 2) {
                    callback = opts;
                    opts = {};
                }
                if (datastore.cache.cacheEnabled(opts.cache)) {
                    var res = datastore.cache.tryCache(provider, opts.cache);
                    if (res) {
                        defer.resolve(res);
                        if (callback) return callback(null, res);
                        else return;
                    }
                }
                if (!opts.state) {
                    opts.state = sha1.create_hash();
                    opts.state_type = "client";
                }
                client_states.push(opts.state);
                var url = config.oauthd_url + '/auth/' + provider + "?k=" + config.key;
                url += '&d=' + encodeURIComponent(Url.getAbsUrl('/'));
                if (opts) url += "&opts=" + encodeURIComponent(JSON.stringify(opts));
                // create popup
                var wnd_settings = {
                    width: Math.floor(window.outerWidth * 0.8),
                    height: Math.floor(window.outerHeight * 0.5)
                };
                if (wnd_settings.height < 350) wnd_settings.height = 350;
                if (wnd_settings.width < 800) wnd_settings.width = 800;
                wnd_settings.left = window.screenX + (window.outerWidth - wnd_settings.width) / 2;
                wnd_settings.top = window.screenY + (window.outerHeight - wnd_settings.height) / 8;
                var wnd_options = "width=" + wnd_settings.width + ",height=" + wnd_settings.height;
                wnd_options += ",toolbar=0,scrollbars=1,status=1,resizable=1,location=1,menuBar=0";
                wnd_options += ",left=" + wnd_settings.left + ",top=" + wnd_settings.top;
                opts = {
                    provider: provider,
                    cache: opts.cache
                };

                function getMessage(e) {
                    if (e.origin !== config.oauthd_base) return;
                    try {
                        wnd.close();
                    } catch (e) {}
                    opts.data = e.data;
                    return oauthio.request.sendCallback(opts, defer);
                }
                opts.callback = function(e, r) {
                    if (window.removeEventListener) window.removeEventListener("message", getMessage, false);
                    else if (window.detachEvent) window.detachEvent("onmessage", getMessage);
                    else if (document.detachEvent) document.detachEvent("onmessage", getMessage);
                    opts.callback = function() {};
                    if (wndTimeout) {
                        clearTimeout(wndTimeout);
                        wndTimeout = undefined;
                    }
                    return callback ? callback(e, r) : undefined;
                };
                if (window.attachEvent) window.attachEvent("onmessage", getMessage);
                else if (document.attachEvent) document.attachEvent("onmessage", getMessage);
                else if (window.addEventListener) window.addEventListener("message", getMessage, false);
                if (typeof chrome != 'undefined' && chrome.runtime && chrome.runtime.onMessageExternal) chrome.runtime.onMessageExternal.addListener(function(request, sender, sendResponse) {
                    request.origin = sender.url.match(/^.{2,5}:\/\/[^/]+/)[0]
                    defer.resolve();
                    return getMessage(request);
                });
                if (!frm && (navigator.userAgent.indexOf('MSIE') !== -1 || navigator.appVersion.indexOf('Trident/') > 0)) {
                    frm = document.createElement("iframe");
                    frm.src = config.oauthd_url + "/auth/iframe?d=" + encodeURIComponent(Url.getAbsUrl('/'));
                    frm.width = 0
                    frm.height = 0
                    frm.frameBorder = 0
                    frm.style.visibility = "hidden";
                    document.body.appendChild(frm);
                }
                wndTimeout = setTimeout(function() {
                    defer.reject(new Error('Authorization timed out'));
                    if (opts.callback)
                        opts.callback(new Error('Authorization timed out'));
                    try {
                        wnd.close();
                    } catch (e) {}
                }, 1200 * 1000);
                wnd = window.open(url, "Authorization", wnd_options);
                if (wnd) wnd.focus();
                else {
                    defer.reject(new Error("Could not open a popup"));
                    if (opts.callback) opts.callback(new Error("Could not open a popup"));
                }

                return defer.promise();
            },
            redirect: function(provider, opts, url) {
                if (arguments.length == 2) {
                    url = opts;
                    opts = {};
                }
                if (datastore.cache.cacheEnabled(opts.cache)) {
                    var res = datastore.cache.tryCache(provider, opts.cache);
                    if (res) {
                        url = Url.getAbsUrl(url) + ((url.indexOf('#') === -1) ? '#' : '&') + 'oauthio=cache';
                        document.location.href = url;
                        document.location.reload();
                        return;
                    }
                }
                if (!opts.state) {
                    opts.state = sha1.create_hash();
                    opts.state_type = "client";
                }
                datastore.cookies.createCookie("oauthio_state", opts.state);
                var redirect_uri = encodeURIComponent(Url.getAbsUrl(url));
                url = config.oauthd_url + '/auth/' + provider + "?k=" + config.key;
                url += "&redirect_uri=" + redirect_uri;
                if (opts) url += "&opts=" + encodeURIComponent(JSON.stringify(opts));
                document.location.href = url;
            },
            callback: function(provider, opts, callback) {
                if (arguments.length == 1) {
                    callback = provider;
                    provider = undefined;
                    opts = {};
                }
                if (arguments.length == 2) {
                    callback = opts;
                    opts = {};
                }
                if (datastore.cache.cacheEnabled(opts.cache) || oauth_result === 'cache') {
                    if (oauth_result === 'cache' && (typeof provider !== 'string' || !provider)) return callback(new Error("You must set a provider when using the cache"));
                    var res = datastore.cache.tryCache(provider, opts.cache);
                    if (res) return callback(null, res);
                }
                if (!oauth_result) return;
                oauthio.request.sendCallback({
                    data: oauth_result,
                    provider: provider,
                    cache: opts.cache,
                    callback: callback
                });
            },
            clearCache: function(provider) {
                datastore.cookies.eraseCookie("oauthio_provider_" + provider);
            },
            http_me: function(opts) {
                if (oauthio.request.http_me)
                    oauthio.request.http_me(opts);
            },
            http: function(opts) {
                if (oauthio.request.http)
                    oauthio.request.http(opts);
            }
        };
        if (typeof jQuery == 'undefined') {
            var _preloadcalls = [];
            var delayfn;
            if (typeof chrome != 'undefined' && chrome.runtime) {
                delayfn = function() {
                    return function() {
                        throw new Error("Please include jQuery before oauth.js");
                    };
                }
            } else {
                var e = document.createElement("script");
                e.src = "//code.jquery.com/jquery.min.js";
                e.type = "text/javascript";
                e.onload = function() {
                    delayedFunctions(jQuery);
                    for (var i in _preloadcalls) _preloadcalls[i].fn.apply(null, _preloadcalls[i].args);
                };
                document.getElementsByTagName("head")[0].appendChild(e);
                delayfn = function(f) {
                    return function() {
                        var args_copy = [];
                        for (var arg in arguments) args_copy[arg] = arguments[arg];
                        _preloadcalls.push({
                            fn: f,
                            args: args_copy
                        });
                    }
                };
            }
            oauthio.request.http = delayfn(function() {
                oauthio.request.http.apply(exports.OAuth, arguments);
            })
            providers_api.fetchDescription = delayfn(function() {
                providers_api.fetchDescription.apply(providers_api, arguments);
            });
            oauthio.request = require('./lib/oauthio_requests')(jQuery, config, client_states, datastore);
        } else delayedFunctions(jQuery);
    }

    function delayedFunctions($) {
        oauthio.request = require('./lib/oauthio_requests')($, config, client_states, datastore);
        providers_api.fetchDescription = function(provider) {
            if (providers_desc[provider]) return;
            providers_desc[provider] = true;
            $.ajax({
                url: config.oauthd_base + config.oauthd_api + '/providers/' + provider,
                data: {
                    extend: true
                },
                dataType: 'json'
            }).done(function(data) {
                providers_desc[provider] = data.data;
                providers_api.execProvidersCb(provider, null, data.data);
            }).always(function() {
                if (typeof providers_desc[provider] !== 'object') {
                    delete providers_desc[provider];
                    providers_api.execProvidersCb(provider, new Error("Unable to fetch request description"));
                }
            });
        };
    }
};