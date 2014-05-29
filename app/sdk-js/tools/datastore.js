module.exports = function(config) {
    return {
        cookies: {
            createCookie: function(name, value, expires) {
                eraseCookie(name);
                var date = new Date();
                date.setTime(date.getTime() + (expires || 1200) * 1000); // def: 20 mins
                var expires = "; expires=" + date.toGMTString();
                document.cookie = name + "=" + value + expires + "; path=/";
            },
            readCookie: function(name) {
                var nameEQ = name + "=";
                var ca = document.cookie.split(';');
                for (var i = 0; i < ca.length; i++) {
                    var c = ca[i];
                    while (c.charAt(0) === ' ') c = c.substring(1, c.length);
                    if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
                }
                return null;
            },
            eraseCookie: function(name) {
                var date = new Date();
                date.setTime(date.getTime() - 86400000);
                document.cookie = name + "=; expires=" + date.toGMTString() + "; path=/";
            }
        },
        cache: {
            tryCache: function(provider, cache) {
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
            },
            storeCache: function(provider, cache) {
                createCookie("oauthio_provider_" + provider, encodeURIComponent(JSON.stringify(cache)), cache.expires_in - 10 || 3600);
            },
            cacheEnabled: function(cache) {
                if (typeof cache === 'undefined') return config.options.cache;
                return cache;
            }
        }
    };
}