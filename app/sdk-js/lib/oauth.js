"use strict";

var utilities = require('./utilities');
var config = require('./config');

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
        opts = opts || {}
        if (typeof providers_desc[provider] === 'object') return callback(null, providers_desc[provider]);
        if (!providers_desc[provider]) providers_api.fetchDescription(provider);
        if (!opts.wait) return callback(null, {});
        providers_cb[provider] = providers_cb[provider] || []
        providers_cb[provider].push(callback);
    }
};
config.oauthd_base = getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];
var client_states = [];
var oauth_result;
(function parse_urlfragment() {
    var results = /[\\#&]oauthio=([^&]*)/.exec(document.location.hash);
    if (results) {
        document.location.hash = document.location.hash.replace(/&?oauthio=[^&]*/, '');
        oauth_result = decodeURIComponent(results[1].replace(/\+/g, " "));
        var cookie_state = readCookie("oauthio_state");
        if (cookie_state) {
            client_states.push(cookie_state);
            eraseCookie("oauthio_state");
        }
    }
})();

function getAbsUrl(url) {
    if (url.match(/^.{2,5}:\/\//)) return url;
    if (url[0] === '/') return document.location.protocol + '//' + document.location.host + url;
    var base_url = document.location.protocol + '//' + document.location.host + document.location.pathname;
    if (base_url[base_url.length - 1] != '/' && url[0] != '#') return base_url + '/' + url;
    return base_url + url;
}

function replaceParam(param, rep, rep2) {
    param = param.replace(/\{\{(.*?)\}\}/g, function(m, v) {
        return rep[v] || "";
    });
    if (rep2) param = param.replace(/\{(.*?)\}/g, function(m, v) {
        return rep2[v] || "";
    });
    return param;
}

function mkHttp(provider, tokens, request, method) {
    return function(opts, opts2) {
        var options = {};
        if (typeof opts === 'string') {
            if (typeof opts2 === 'object')
                for (var i in opts2) {
                    options[i] = opts2[i];
                }
            options.url = opts;
        } else if (typeof opts === 'object')
            for (var i in opts) {
                options[i] = opts[i];
            }
        options.type = options.type || method;
        options.oauthio = {
            provider: provider,
            tokens: tokens,
            request: request
        };
        return exports.OAuth.http(options);
    };
};

function mkHttpMe(provider, tokens, request, method) {
    return function(filter) {
        var options = {};
        options.type = options.type || method;
        options.oauthio = {
            provider: provider,
            tokens: tokens,
            request: request
        };
        options.data = options.data || {};
        options.data.filter = filter ? filter.join(',') : undefined;
        return exports.OAuth.http_me(options);
    };
};

function sendCallback(opts, defer) {
    var data;
    var err;
    try {
        data = JSON.parse(opts.data);
    } catch (e) {
        defer.reject(new Error('Error while parsing result'));
        return opts.callback(new Error('Error while parsing result'));
    }
    if (!data || !data.provider) return;
    if (opts.provider && data.provider.toLowerCase() !== opts.provider.toLowerCase()) return;
    if (data.status === 'error' || data.status === 'fail') {
        err = new Error(data.message);
        err.body = data.data;
        defer.reject(err);
        if (opts.callback) {
            return opts.callback(err);
        } else {
            return;
        }
    }
    if (data.status !== 'success' || !data.data) {
        err = new Error();
        err.body = data.data;
        defer.reject(err);
        if (opts.callback) return opts.callback(err);
        else return;
    }
    if (!data.state || client_states.indexOf(data.state) == -1) {
        defer.reject(new Error('State is not matching'));
        if (opts.callback) return opts.callback(new Error('State is not matching'));
        else return;
    }
    if (!opts.provider) data.data.provider = data.provider;
    var res = data.data;
    if (cacheEnabled(opts.cache) && res) storeCache(data.provider, res);
    var request = res.request;
    delete res.request;
    var tokens;
    if (res.access_token) tokens = {
        access_token: res.access_token
    };
    else if (res.oauth_token && res.oauth_token_secret) tokens = {
        oauth_token: res.oauth_token,
        oauth_token_secret: res.oauth_token_secret
    };
    if (!request) {
        defer.resolve(res);
        if (opts.callback) return opts.callback(null, res);
        else return;
    }
    if (request.required)
        for (var i in request.required) tokens[request.required[i]] = res[request.required[i]];
    var make_res = function(method) {
        return mkHttp(data.provider, tokens, request, method);
    }

    res.get = make_res('GET');
    res.post = make_res('POST');
    res.put = make_res('PUT');
    res.patch = make_res('PATCH');
    res.del = make_res('DELETE');

    res.me = mkHttpMe(data.provider, tokens, request, 'GET');

    defer.resolve(res);
    if (opts.callback) return opts.callback(null, res);
    else return;
}

function tryCache(provider, cache) {
    if (cacheEnabled(cache)) {
        cache = readCookie("oauthio_provider_" + provider);
        if (!cache) return false;
        cache = decodeURIComponent(cache);
    }
    if (typeof cache === 'string') {
        try {
            cache = JSON.parse(cache);
        } catch (e) {
            return false;
        }
    }
    if (typeof cache === "object") {
        var res = {};
        for (var i in cache)
            if (i !== 'request' && typeof cache[i] !== 'function') res[i] = cache[i];
        return exports.OAuth.create(provider, res, cache.request);
    }
    return false;
}

function storeCache(provider, cache) {
    createCookie("oauthio_provider_" + provider, encodeURIComponent(JSON.stringify(cache)), cache.expires_in - 10 || 3600);
}

function cacheEnabled(cache) {
    if (typeof cache === 'undefined') return config.options.cache;
    return cache;
}

function create_hash() {
    var hash = utilities.b64_sha1((new Date()).getTime() + ':' + Math.floor(Math.random() * 9999999));
    return hash.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '');
}

function createCookie(name, value, expires) {
    eraseCookie(name);
    var date = new Date();
    date.setTime(date.getTime() + (expires || 1200) * 1000); // def: 20 mins
    var expires = "; expires=" + date.toGMTString();
    document.cookie = name + "=" + value + expires + "; path=/";
}

function readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) === ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
}

function eraseCookie(name) {
    var date = new Date();
    date.setTime(date.getTime() - 86400000);
    document.cookie = name + "=; expires=" + date.toGMTString() + "; path=/";
}

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
                config.oauthd_base = getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];
            },
            getVersion: function() {
                return config.version;
            },
            create: function(provider, tokens, request) {
                if (!tokens) return tryCache(provider, true);
                if (typeof request !== 'object') providers_api.fetchDescription(provider);
                var make_res = function(method) {
                    return mkHttp(provider, tokens, request, method);
                }
                var make_res_endpoint = function(method, url) {
                    return mkHttpEndpoint(data.provider, tokens, request, method, url);
                }
                var res = {};
                for (var i in tokens) res[i] = tokens[i];
                res.get = make_res('GET');
                res.post = make_res('POST');
                res.put = make_res('PUT');
                res.patch = make_res('PATCH');
                res.del = make_res('DELETE');

                res.me = function(opts) {
                    mkHttpMe(data.provider, tokens, request, 'GET');
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
                if (cacheEnabled(opts.cache)) {
                    var res = tryCache(provider, opts.cache);
                    if (res) {
                        defer.resolve(res);
                        if (callback) return callback(null, res);
                        else return;
                    }
                }
                if (!opts.state) {
                    opts.state = create_hash();
                    opts.state_type = "client";
                }
                client_states.push(opts.state);
                var url = config.oauthd_url + '/auth/' + provider + "?k=" + config.key;
                url += '&d=' + encodeURIComponent(getAbsUrl('/'));
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
                    return sendCallback(opts, defer);
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
                    frm.src = config.oauthd_url + "/auth/iframe?d=" + encodeURIComponent(getAbsUrl('/'));
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
                if (cacheEnabled(opts.cache)) {
                    var res = tryCache(provider, opts.cache);
                    if (res) {
                        url = getAbsUrl(url) + ((url.indexOf('#') === -1) ? '#' : '&') + 'oauthio=cache';
                        document.location.href = url;
                        document.location.reload();
                        return;
                    }
                }
                if (!opts.state) {
                    opts.state = create_hash();
                    opts.state_type = "client";
                }
                createCookie("oauthio_state", opts.state);
                var redirect_uri = encodeURIComponent(getAbsUrl(url));
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
                if (cacheEnabled(opts.cache) || oauth_result === 'cache') {
                    if (oauth_result === 'cache' && (typeof provider !== 'string' || !provider)) return callback(new Error("You must set a provider when using the cache"));
                    var res = tryCache(provider, opts.cache);
                    if (res) return callback(null, res);
                }
                if (!oauth_result) return;
                sendCallback({
                    data: oauth_result,
                    provider: provider,
                    cache: opts.cache,
                    callback: callback
                });
            },
            clearCache: function(provider) {
                eraseCookie("oauthio_provider_" + provider);
            }
        };
        // if (typeof jQuery == 'undefined') {
        //     var _preloadcalls = [];
        //     var delayfn;
        //     if (typeof chrome != 'undefined' && chrome.runtime) {
        //         delayfn = function() {
        //             return function() {
        //                 throw new Error("Please include jQuery before oauth.js");
        //             };
        //         }
        //     } else {
        //         var e = document.createElement("script");
        //         e.src = "//code.jquery.com/jquery.min.js";
        //         e.type = "text/javascript";
        //         e.onload = function() {
        //             delayedFunctions(jQuery);
        //             for (var i in _preloadcalls) _preloadcalls[i].fn.apply(null, _preloadcalls[i].args);
        //         };
        //         document.getElementsByTagName("head")[0].appendChild(e);
        //         delayfn = function(f) {
        //             return function() {
        //                 var args_copy = [];
        //                 for (var arg in arguments) args_copy[arg] = arguments[arg];
        //                 _preloadcalls.push({
        //                     fn: f,
        //                     args: args_copy
        //                 });
        //             }
        //         };
        //     }
        //     exports.OAuth.http = delayfn(function() {
        //         exports.OAuth.http.apply(exports.OAuth, arguments)
        //     })
        //     providers_api.fetchDescription = delayfn(function() {
        //         providers_api.fetchDescription.apply(providers_api, arguments)
        //     });
        // } else delayedFunctions(jQuery);
    }

    var $ = require('./bower_components/jquery/dist/jquery.min');

    function delayedFunctions($) {
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

        exports.OAuth.http_me = function(opts) {
            var options = {};
            for (var k in opts) {
                options[k] = opts[k];
            }
            if (!options.oauthio.request || options.oauthio.request === true) {
                var desc_opts = {
                    wait: !! options.oauthio.request
                };
                var defer = $.Deferred();
                providers_api.getDescription(options.oauthio.provider, desc_opts, function(e, desc) {
                    if (e) return defer.reject(e);
                    if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) options.oauthio.request = desc.oauth1 && desc.oauth1.request;
                    else options.oauthio.request = desc.oauth2 && desc.oauth2.request;
                    defer.resolve();
                });
                return defer.then(doRequest);
            } else return doRequest();

            function doRequest() {
                var defer = $.Deferred();
                var request = options.oauthio.request || {};
                options.url = config.oauthd_url + '/auth/' + options.oauthio.provider + '/me';
                options.headers = options.headers || {};
                options.headers.oauthio = 'k=' + config.key;
                if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) options.headers.oauthio += '&oauthv=1'; // make sure to use oauth 1
                for (var k in options.oauthio.tokens) options.headers.oauthio += '&' + encodeURIComponent(k) + '=' + encodeURIComponent(options.oauthio.tokens[k]);
                delete options.oauthio;
                var promise = $.ajax(options);
                $.when(promise)
                    .done(function(data) {
                        defer.resolve(data.data);
                    })
                    .fail(function(data) {
                        if (data.responseJSON) {
                            defer.reject(data.responseJSON.data);
                        } else {
                            defer.reject(new Error('An error occured while trying to access the resource'));
                        }
                    });
                return defer.promise();
            }
        };

        exports.OAuth.http = function(opts) {
            var options = {};
            var i;
            for (i in opts) {
                options[i] = opts[i];
            }
            if (!options.oauthio.request || options.oauthio.request === true) {
                var desc_opts = {
                    wait: !! options.oauthio.request
                };
                var defer = $.Deferred();
                providers_api.getDescription(options.oauthio.provider, desc_opts, function(e, desc) {
                    if (e) return defer.reject(e);
                    if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) options.oauthio.request = desc.oauth1 && desc.oauth1.request;
                    else options.oauthio.request = desc.oauth2 && desc.oauth2.request;
                    defer.resolve();
                });
                return defer.then(doRequest);
            } else return doRequest();

            function doRequest() {
                var request = options.oauthio.request || {};
                if (!request.cors) {
                    options.url = encodeURIComponent(options.url);
                    if (options.url[0] != '/') options.url = '/' + options.url;
                    options.url = config.oauthd_url + '/request/' + options.oauthio.provider + options.url;
                    options.headers = options.headers || {};
                    options.headers.oauthio = 'k=' + config.key;
                    if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) options.headers.oauthio += '&oauthv=1'; // make sure to use oauth 1
                    for (var k in options.oauthio.tokens) options.headers.oauthio += '&' + encodeURIComponent(k) + '=' + encodeURIComponent(options.oauthio.tokens[k]);
                    delete options.oauthio;
                    return $.ajax(options);
                }
                if (options.oauthio.tokens) {
                    //Fetching the url if a common endpoint is called
                    if (options.oauthio.tokens.access_token) options.oauthio.tokens.token = options.oauthio.tokens.access_token;
                    if (!options.url.match(/^[a-z]{2,16}:\/\//)) {
                        if (options.url[0] !== '/') options.url = '/' + options.url;
                        options.url = request.url + options.url;
                    }
                    options.url = replaceParam(options.url, options.oauthio.tokens, request.parameters);
                    if (request.query) {
                        var qs = [];
                        for (i in request.query) qs.push(encodeURIComponent(i) + '=' + encodeURIComponent(replaceParam(request.query[i], options.oauthio.tokens, request.parameters)));
                        qs = qs.join('&');
                        if (options.url.indexOf('?') !== -1) options.url += '&' + qs;
                        else options.url += '?' + qs;
                    }
                    if (request.headers) {
                        options.headers = options.headers || {};
                        for (i in request.headers) options.headers[i] = replaceParam(request.headers[i], options.oauthio.tokens, request.parameters);
                    }
                    delete options.oauthio;
                    return $.ajax(options);
                }
            };
        }
    }


};