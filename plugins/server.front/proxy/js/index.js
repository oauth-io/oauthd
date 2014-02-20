var request, transform_urls, url;

url = require('url');

request = require('request');

transform_urls = function(data, host) {
  data = data.replace(/src=[\"'](\/.+?)[\"']/g, 'src="' + '/proxy?url=' + host + '$1' + '"');
  data = data.replace(/href=[\"'](\/.+?)[\"']/g, 'href="' + '/proxy?url=' + host + '$1' + '"');
  data = data.replace(/src=[\"'](http:.+?)[\"']/g, 'src="' + '/proxy?url=' + '$1' + '"');
  data = data.replace(/href=[\"'](http:.+?)[\"']/g, 'href="' + '/proxy?url=' + '$1' + '"');
  data = data.replace(/[\"'](http:.+?)[\"']/g, '"' + '/proxy?url=' + '$1' + '"');
  return data;
};

module.exports = function(req, res, next) {
  var options, urlDecoded;
  url = url.parse(req.params.url);
  urlDecoded = decodeURIComponent(req.params.url);
  options = {
    uri: urlDecoded,
    method: 'GET',
    'user-agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36'
  };
  return request(options, function(err, response, body) {
    var result;
    result = transform_urls(body, url.protocol + '//' + url.host);
    res.writeHead(200, {
      'Content-Length': Buffer.byteLength(result),
      'Content-Type': response.headers['content-type']
    });
    res.write(result);
    return res.end();
  });
};
