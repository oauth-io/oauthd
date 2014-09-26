var crypto, restify, restifyOAuth2;

crypto = require('crypto');

restify = require('restify');

restifyOAuth2 = require('restify-oauth2-oauthd');

module.exports = function(env) {
  var auth, db_login, db_register, hooks, _config;
  auth = {};
  _config = {
    expire: 3600 * 5
  };
  db_register = env.utilities.check({
    name: /^.{3,42}$/,
    pass: /^.{6,42}$/
  }, function(data, callback) {
    return env.data.redis.get('adm:pass', function(e, r) {
      var dynsalt, pass;
      if (e || r) {
        return callback(new env.utilities.check.Error('Unable to register'));
      }
      dynsalt = Math.floor(Math.random() * 9999999);
      pass = env.data.generateHash(data.pass + dynsalt);
      return env.data.redis.mset('adm:salt', dynsalt, 'adm:pass', pass, 'adm:name', data.name, function(err, res) {
        if (err) {
          return callback(err);
        }
        return callback();
      });
    });
  });
  db_login = env.utilities.check({
    name: /^.{3,42}$/,
    pass: /^.{6,42}$/
  }, function(data, callback) {
    return env.data.redis.mget(['adm:pass', 'adm:name', 'adm:salt'], function(err, replies) {
      var calcpass;
      if (err) {
        return callback(err);
      }
      if (!replies[1]) {
        return callback(null, false);
      }
      calcpass = env.data.generateHash(data.pass + replies[2]);
      if (replies[0] !== calcpass || replies[1] !== data.name) {
        return callback(new env.utilities.check.Error("Invalid email or password"));
      }
      return callback(null, replies[1]);
    });
  });
  hooks = {
    grantClientToken: function(clientId, clientSecret, cb) {
      var next;
      if (env.data.redis.last_error) {
        return cb(new env.utilities.check.Error(env.data.redis.last_error));
      }
      next = function() {
        var token;
        token = env.data.generateUid();
        return (env.data.redis.multi([['hmset', 'session:' + token, 'date', (new Date).getTime()], ['expire', 'session:' + token, _config.expire]])).exec(function(err, r) {
          if (err) {
            return cb(err);
          }
          return cb(null, token);
        });
      };
      return db_login({
        name: clientId,
        pass: clientSecret
      }, function(err, res) {
        if (err) {
          if (err.message === "Invalid email or password") {
            return cb(null, false);
          }
          if (err) {
            return cb(err);
          }
        }
        if (res) {
          return next();
        }
        return db_register({
          name: clientId,
          pass: clientSecret
        }, function(err, res) {
          if (err) {
            return cb(err);
          }
          return next();
        });
      });
    },
    authenticateToken: function(token, cb) {
      if (env.data.redis.last_error) {
        return cb(null, false);
      }
      return env.data.redis.hgetall('session:' + token, function(err, res) {
        if (err) {
          return cb(err);
        }
        if (!res) {
          return cb(null, false);
        }
        return cb(null, res);
      });
    }
  };
  auth.init = function() {
    return restifyOAuth2.cc(env.server, {
      hooks: hooks,
      tokenEndpoint: env.config.base + '/token',
      tokenExpirationTime: _config.expire
    });
  };
  auth.needed = function(req, res, next) {
    var cb, token;
    cb = function() {
      req.user = req.clientId;
      if (req.body == null) {
        req.body = {};
      }
      return next();
    };
    if (env.data.redis.last_error) {
      return cb();
    }
    if (req.clientId) {
      return cb();
    }
    token = req.headers.Authorization.replace(/^Bearer /, '');
    console.log('token', token);
    if (!token) {
      return next(new restify.ResourceNotFoundError(req.url + ' does not exist'));
    }
    return env.data.redis.hget('session:' + token, 'date', function(err, res) {
      if (!res) {
        return next(new restify.ResourceNotFoundError(req.url + ' does not exist'));
      }
      req.clientId = 'admin';
      return cb();
    });
  };
  auth.optional = function(req, res, next) {
    var cb, token, _ref;
    cb = function() {
      req.user = req.clientId;
      if (req.body == null) {
        req.body = {};
      }
      return next();
    };
    if (env.data.redis.last_error) {
      return cb();
    }
    if (req.clientId) {
      return cb();
    }
    token = (_ref = req.headers.cookie) != null ? _ref.match(/accessToken=%22(.*?)%22/) : void 0;
    token = token != null ? token[1] : void 0;
    if (!token) {
      return cb();
    }
    return env.data.redis.hget('session:' + token, 'date', function(err, res) {
      if (!res) {
        return cb();
      }
      req.clientId = 'admin';
      return cb();
    });
  };
  auth.setup = function(callback) {
    env.server.post(env.config.base + '/signin', (function(_this) {
      return function(req, res, next) {
        res.setHeader('Content-Type', 'text/html');
        return hooks.grantClientToken(req.body.name, req.body.pass, function(e, token) {
          var expireDate;
          if (!e && !token) {
            e = new env.utilities.check.Error('Invalid email or password');
          }
          if (token) {
            expireDate = new Date((new Date - 0) + _config.expire * 1000);
            res.json({
              accessToken: token,
              expires: expireDate.getTime()
            });
          }
          if (e) {
            if (e.status === "fail") {
              if (e.body.name) {
                e = new env.utilities.check.Error("Invalid email format");
              }
              if (e.body.pass) {
                e = new env.utilities.check.Error("Invalid password format (must be 6 characters min)");
              }
            }
            res.send(400, e.message);
          }
          return next();
        });
      };
    })(this));
    env.server.get(env.config.base + '/api/apps', auth.needed, function(req, res, next) {
      return env.data.apps.getByOwner('undefined', function(err, apps) {
        return res.json(apps);
      });
    });
    return callback();
  };
  return auth;
};
