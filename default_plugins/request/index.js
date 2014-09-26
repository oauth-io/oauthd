var Url, async, qs, request, restify;

async = require('async');

qs = require('querystring');

Url = require('url');

restify = require('restify');

request = require('request');

module.exports = function(env) {
  var exp, oauth;
  oauth = env.utilities.oauth;
  exp = {};
  exp.apiRequest = (function(_this) {
    return function(req, provider_name, oauthio, callback) {
      if (req.headers == null) {
        req.headers = {};
      }
      return async.parallel([
        function(callback) {
          return env.data.providers.getExtended(provider_name, callback);
        }, function(callback) {
          return env.data.apps.getKeyset(oauthio.k, provider_name, callback);
        }
      ], function(err, results) {
        var oa, oauthv, parameters, provider, _ref;
        if (err) {
          return callback(err);
        }
        provider = results[0], (_ref = results[1], parameters = _ref.parameters);
        oauthv = oauthio.oauthv && {
          "2": "oauth2",
          "1": "oauth1"
        }[oauthio.oauthv];
        if (oauthv && !provider[oauthv]) {
          return callback(new env.utilities.check.Error("oauthio_oauthv", "Unsupported oauth version: " + oauthv));
        }
        if (provider.oauth2) {
          if (oauthv == null) {
            oauthv = 'oauth2';
          }
        }
        if (provider.oauth1) {
          if (oauthv == null) {
            oauthv = 'oauth1';
          }
        }
        parameters.oauthio = oauthio;
        oa = new oauth[oauthv](provider, parameters);
        return oa.request(req, callback);
      });
    };
  })(this);
  exp.raw = function() {
    var doRequest, fixUrl;
    fixUrl = function(ref) {
      return ref.replace(/^([a-zA-Z\-_]+:\/)([^\/])/, '$1/$2');
    };
    doRequest = (function(_this) {
      return function(req, res, next) {
        var cb, oauthio, origin, ref, urlinfos;
        cb = env.server.send(res, next);
        oauthio = req.headers.oauthio;
        if (!oauthio) {
          return cb(new env.utilities.check.Error("You must provide a valid 'oauthio' http header"));
        }
        oauthio = qs.parse(oauthio);
        if (!oauthio.k) {
          return cb(new env.utilities.check.Error("oauthio_key", "You must provide a 'k' (key) in 'oauthio' header"));
        }
        origin = null;
        ref = fixUrl(req.headers['referer'] || req.headers['origin'] || "http://localhost");
        urlinfos = Url.parse(ref);
        if (!urlinfos.hostname) {
          ref = origin = "http://localhost";
        } else {
          origin = urlinfos.protocol + '//' + urlinfos.host;
        }
        req.apiUrl = decodeURIComponent(req.params[1]);
        env.data.apps.checkDomain(oauthio.k, ref, function(err, domaincheck) {
          if (err) {
            return cb(err);
          }
          if (!domaincheck) {
            return cb(new env.utilities.check.Error('Origin "' + ref + '" does not match any registered domain/url on ' + env.config.url.host));
          }
        });
        return exp.apiRequest(req, req.params[0], oauthio, function(err, options) {
          var api_request, bodyParser, sendres;
          if (err) {
            return cb(err);
          }
          env.events.emit('request', {
            provider: req.params[0],
            key: oauthio.k
          });
          api_request = null;
          sendres = function() {
            api_request.pipefilter = function(response, dest) {
              dest.setHeader('Access-Control-Allow-Origin', origin);
              return dest.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE');
            };
            api_request.pipe(res);
            return api_request.once('end', function() {
              return next(false);
            });
          };
          if (req.headers['content-type'] && req.headers['content-type'].indexOf('application/x-www-form-urlencoded') !== -1) {
            bodyParser = restify.bodyParser({
              mapParams: false
            });
            return bodyParser[0](req, res, function() {
              return bodyParser[1](req, res, function() {
                options.form = req.body;
                delete options.headers['Content-Length'];
                api_request = request(options);
                return sendres();
              });
            });
          } else {
            api_request = request(options);
            delete req.headers;
            api_request = req.pipe(api_request);
            return sendres();
          }
        });
      };
    })(this);
    env.server.opts(new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), function(req, res, next) {
      var origin, ref, urlinfos;
      origin = null;
      ref = fixUrl(req.headers['referer'] || req.headers['origin'] || "http://localhost");
      urlinfos = Url.parse(ref);
      if (!urlinfos.hostname) {
        return next(new restify.InvalidHeaderError('Missing origin or referer.'));
      }
      origin = urlinfos.protocol + '//' + urlinfos.host;
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE');
      if (req.headers['access-control-request-headers']) {
        res.setHeader('Access-Control-Allow-Headers', req.headers['access-control-request-headers']);
      }
      res.cache({
        maxAge: 120
      });
      res.send(200);
      return next(false);
    });
    env.server.get(new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest);
    env.server.post(new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest);
    env.server.put(new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest);
    env.server.patch(new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest);
    return env.server.del(new RegExp('^/request/([a-zA-Z0-9_\\.~-]+)/(.*)$'), doRequest);
  };
  return exp;
};
