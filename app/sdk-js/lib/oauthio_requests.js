module.exports = function($, config, client_states, datastore) {
    return {
        http: function(opts) {
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
        },
        http_me: function(opts) {
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
        },
        mkHttp: function(provider, tokens, request, method) {
            var base = this;
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
                return base.http(options);
            };
        },
        mkHttpMe: function(provider, tokens, request, method) {
            var base = this;
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
                return base.http_me(options);
            };
        },
        sendCallback: function(opts, defer) {
            var base = this;
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
            if (datastore.cache.cacheEnabled(opts.cache) && res) datastore.cache.storeCache(data.provider, res);
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
                return base.mkHttp(data.provider, tokens, request, method);
            }

            res.get = make_res('GET');
            res.post = make_res('POST');
            res.put = make_res('PUT');
            res.patch = make_res('PATCH');
            res.del = make_res('DELETE');

            res.me = base.mkHttpMe(data.provider, tokens, request, 'GET');

            defer.resolve(res);
            if (opts.callback) return opts.callback(null, res);
            else return;
        }
    };
}