var ContentManager;

ContentManager = (function() {
  function ContentManager(owner, repo) {
    this.owner = owner;
    this.repo = repo;
    this.files = {};
  }

  ContentManager.prototype.getBaseUrl = function() {
    return 'https://api.github.com/repos/' + this.owner + '/' + this.repo + '/contents/';
  };

  ContentManager.prototype.getExtension = function(filename) {
    var regexp, res;
    regexp = /[a-zA-Z0-9-_]+\.([a-z]{1,4})/i;
    res = regexp.match(filename);
    return res[1];
  };

  ContentManager.prototype.getContentRaw = function(filename, callback) {
    if (!filename) {
      return callback(null);
    }
    if (this.files[filename]) {
      return callback(this.file[filename]);
    }
    return $.get(this.getBaseUrl() + filename + "?ref=master", {}, (function(_this) {
      return function(data) {
        _this.files[filename] = data;
        if (callback) {
          return callback(data);
        }
      };
    })(this));
  };

  ContentManager.prototype.compile = function(data) {
    var regexp, res;
    regexp = /\[\[\s?include ([a-zA-Z0-9-_.\/]+)\s?\]\]\s+(.*)\s+\[\[\s?\/include\s?\]\]/gi;
    res = data.match(regexp);
    console.log(res);
    if (!res) {
      return data;
    }
  };

  ContentManager.prototype.getContent = function(filename, callback) {
    if (!filename) {
      return callback(null);
    }
    return this.getContentRaw(filename, (function(_this) {
      return function(data) {
        if (!data) {
          return callback(null);
        }
        if (_this.getExtension(filename) === 'md') {
          data = compile(data);
          if (typeof data === 'string') {
            return callback(marked(data));
          }
        }
        return callback(data);
      };
    })(this));
  };

  ContentManager.prototype.preload = function(files, callback) {};

  return ContentManager;

})();
