var Content, async, fs, marked, path, request, restify;

restify = require('restify');

path = require('path');

fs = require('fs');

marked = require('marked');

async = require('async');

request = require('request');

Content = (function() {
  function Content() {
    this.raw = {};
    this.content = {};
  }

  Content.prototype.getBaseUrl = function() {
    return 'https://api.github.com/repos/' + this.owner + '/' + this.repo + '/contents/';
  };

  Content.prototype.getExtension = function(filename) {
    var res;
    res = filename.match(/[a-zA-Z0-9-_]+\.([a-z]{1,4})/i);
    return res[1];
  };

  Content.prototype.getSlug = function(filename) {
    var res;
    res = filename.match(/([a-zA-Z0-9-_]+)\.[a-z]{1,4}/i);
    return res[1];
  };

  Content.prototype.getContentRaw = function(filename, callback) {
    var branch, options;
    if (!filename) {
      return callback('no file');
    }
    if (this.raw[filename]) {
      return callback(null, this.raw[filename]);
    }
    branch = 'master';
    if (this.mode === 'draft') {
      branch = this.getSlug(filename);
    }
    options = {
      url: this.getBaseUrl() + filename + "?ref=" + branch,
      headers: {
        'User-Agent': 'OAuth.io',
        'Accept': 'application/vnd.github.V3.raw'
      },
      auth: {
        user: this.username,
        pass: this.password
      }
    };
    return request.get(options, (function(_this) {
      return function(err, res, data) {
        if (err || res.statusCode !== 200) {
          return callback(err);
        }
        _this.raw[filename] = data;
        return callback(null, data);
      };
    })(this));
  };

  Content.prototype.compile = function(data) {
    var fragment, match, regexp, res, results, _i, _len;
    regexp = /\[\[ ?fragment ([a-zA-Z0-9-_]+) ?\]\]((.*\s*)*?)\[\[ ?\/fragment ?\]\]/gi;
    res = data.match(regexp);
    if (!res) {
      return marked(data);
    }
    results = {};
    regexp = /\[\[ ?fragment ([a-zA-Z0-9-_]+) ?\]\]((.*\s*)*?)\[\[ ?\/fragment ?\]\]/i;
    for (_i = 0, _len = res.length; _i < _len; _i++) {
      fragment = res[_i];
      match = fragment.match(regexp);
      results[match[1]] = marked(match[2].trim());
    }
    return results;
  };

  Content.prototype.getContent = function(filename, fragment, callback) {
    var c, f, _i, _len;
    if (!callback) {
      callback = fragment;
      fragment = null;
    }
    if (!filename) {
      return callback("filename null");
    }
    if (this.content[filename]) {
      if (!fragment) {
        return callback(null, this.content[filename]);
      }
      if (typeof fragment === 'string' && this.content[filename][fragment]) {
        return callback(null, this.content[filename][fragment]);
      }
      if ((fragment != null ? fragment.length : void 0) > 0) {
        c = [];
        for (_i = 0, _len = fragment.length; _i < _len; _i++) {
          f = fragment[_i];
          if (this.content[filename][f]) {
            c.push(this.content[filename][f]);
          }
        }
        return callback(null, c);
      }
    }
    return this.getContentRaw(filename, (function(_this) {
      return function(err, data) {
        var _j, _len1;
        if (err || !data) {
          return callback('No data in ' + filename);
        }
        if (_this.getExtension(filename) === 'md') {
          data = _this.compile(data);
        }
        _this.content[filename] = data;
        if (fragment) {
          if (typeof fragment === 'string' && data[fragment]) {
            return callback(null, data[fragment]);
          }
          if (fragment.length > 0) {
            c = [];
            for (_j = 0, _len1 = fragment.length; _j < _len1; _j++) {
              f = fragment[_j];
              if (data[f]) {
                c.push(data[f]);
              }
            }
            return callback(null, c);
          }
        }
        return callback(null, data);
      };
    })(this));
  };

  Content.prototype.serve = function(options) {
    var p;
    p = path.normalize(options.directory).replace(/\\/g, '/');
    this.owner = options.owner;
    this.repo = options.repo;
    this.mode = options.mode;
    this.username = options.user || options.username;
    this.password = options.pass || options.password;
    return (function(_this) {
      return function(req, res, next) {
        var file;
        file = path.normalize(path.join(options.directory, req.path())).replace(/\\/g, '/');
        if (req.method !== 'GET' && req.method !== 'HEAD') {
          next(new restify.MethodNotAllowedError(req.method));
          return;
        }
        if (file.substr(0, p.length) !== p) {
          next(new restify.NotAuthorizedError(req.path()));
          return;
        }
        return fs.readFile(file, 'utf8', function(err, data) {
          var f, files, includes, m, results, u, _fn, _i, _j, _len, _len1;
          results = data.match(/\[\[\s?include ([a-zA-Z0-9-_.\/]+)(\#([a-zA-Z0-9-_.]+))?\s?\]\]/gi);
          if (results) {
            m = [];
            includes = {};
            files = [];
            _fn = function(u) {
              var arr;
              arr = u.match(/\[\[\s?include ([a-zA-Z0-9-_.\/]+)(\#([a-zA-Z0-9-_.]+))?\s?\]\]/i);
              if (!includes[arr[1]]) {
                includes[arr[1]] = [];
                files.push(arr[1]);
              }
              return includes[arr[1]].push(arr[3]);
            };
            for (_i = 0, _len = results.length; _i < _len; _i++) {
              u = results[_i];
              _fn(u);
            }
            for (_j = 0, _len1 = files.length; _j < _len1; _j++) {
              f = files[_j];
              m.push(function(callback) {
                return _this.getContent(f, includes[f], callback);
              });
            }
            return async.parallel(m, function(err, contents) {
              var i, tmp, _k, _l, _len2, _len3;
              tmp = [];
              for (_k = 0, _len2 = contents.length; _k < _len2; _k++) {
                i = contents[_k];
                if (typeof i !== 'string' && i.length > 0) {
                  tmp = tmp.concat(i);
                } else if (typeof i === 'string') {
                  tmp.push(i);
                }
              }
              contents = tmp;
              i = 0;
              for (_l = 0, _len3 = results.length; _l < _len3; _l++) {
                u = results[_l];
                data = data.replace(u, contents[i++]);
              }
              res.setHeader('Content-Type', 'text/html');
              res.send(data);
              return next();
            });
          } else {
            res.setHeader('Content-Type', 'text/html');
            res.send(data);
            return next();
          }
        });
      };
    })(this);
  };

  Content.prototype.fetch = function(slug) {};

  return Content;

})();

module.exports = new Content();
