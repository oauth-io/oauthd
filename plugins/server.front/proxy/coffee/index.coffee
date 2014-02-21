url	 = require 'url'
request = require 'request'


transform_urls = (data, host) ->
	data = data.replace /(script.+?src=[\"'])(\/.+?)([\"'])/g, '$1' + '/proxy?url=' + host + '$2' + '$3'
	data = data.replace /(link.+?href=[\"'])(\/.+?)([\"'])/g, '$1' +'/proxy?url=' + host + '$2' + '$3'

	data = data.replace /(script.+?src=[\"'])(http:.+?)([\"'])/g, '$1' + '/proxy?url=' + '$2' + '$3'
	data = data.replace /(link.+?href=[\"'])(http:.+?)([\"'])/g, '$1' +'/proxy?url=' + '$2' + '$3'
	

	data = data.replace /(a.+?href=[\"'])(\/.+?)([\"'])/g, '$1' + host + '$2' + '$3'
	data = data.replace /\ =\ [\"'](http:.+?)[\"']/g, ' = "' + '/proxy?url=' +  '$1' + '"'


	return data

module.exports = (req, res, next) ->
	url = url.parse req.params.url
	urlDecoded = decodeURIComponent ( req.params.url )

	options = 
		uri: urlDecoded,
		method: 'GET',
		'user-agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36'
	

	request options, (err, response, body) ->
		result = transform_urls body, url.protocol + '//' + url.host
		res.writeHead(200, {
			'Content-Length': Buffer.byteLength(result),
			'Content-Type': response.headers['content-type']
		});
		res.write(result);
		res.end();


