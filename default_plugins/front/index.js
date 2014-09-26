var ecstatic, fs, restify;

restify = require('restify');

ecstatic = require('ecstatic');

fs = require('fs');

module.exports = function(env) {
  return {
    setup: function(callback) {
      env.server.get(/^(\/.*)/, function(req, res, next) {
        return fs.stat(__dirname + '/bin/public' + req.params[0], function(err, stat) {
          if (stat != null ? stat.isFile() : void 0) {
            next();
          } else {
            return fs.readFile(__dirname + '/bin/public/index.html', {
              encoding: 'UTF-8'
            }, function(err, data) {
              res.setHeader('Content-Type', 'text/html');
              res.send(200, data);
            });
          }
        });
      }, restify.serveStatic({
        directory: __dirname + '/bin/public',
        "default": __dirname + '/public/index.html'
      }));
      return callback();
    }
  };
};
