restify = require('restify')
path = require('path')
fs = require('fs')
marked = require('marked')
async = require('async')
request = require('request')

class Content
	constructor: ->
		@raw = {}
		@content = {}

	getBaseUrl: () ->
		return 'https://api.github.com/repos/' + @owner + '/' + @repo + '/contents/'

	getExtension: (filename) ->
		res = filename.match /[a-zA-Z0-9-_]+\.([a-z]{1,4})/i
		return res[1]

	getSlug: (filename) ->
		res = filename.match /([a-zA-Z0-9-_]+)\.[a-z]{1,4}/i
		return res[1]

	getContentRaw: (filename, callback) ->
		return callback 'no file' if not filename

		return callback null, @raw[filename] if @raw[filename]
		branch = 'master'
		if @mode == 'draft'
			branch = @getSlug filename

		options =
			url: @getBaseUrl() + filename + "?ref=" + branch
			headers:
			    'User-Agent': 'OAuth.io'
			    'Accept': 'application/vnd.github.V3.raw'
			auth:
				user: @username
				pass: @password

		request.get options, (err, res, data) =>
			return callback err if err or res.statusCode != 200
			@raw[filename] = data
			return callback null, data

	compile: (data) ->
		regexp = /\[\[ ?fragment ([a-zA-Z0-9-_]+) ?\]\]((.*\s*)*?)\[\[ ?\/fragment ?\]\]/gi
		res = data.match regexp
		return marked(data) if not res
		results = {}
		regexp = /\[\[ ?fragment ([a-zA-Z0-9-_]+) ?\]\]((.*\s*)*?)\[\[ ?\/fragment ?\]\]/i
		for fragment in res
			match = fragment.match(regexp)
			results[match[1]] = marked(match[2].trim())
		return results

	getContent: (filename, fragment, callback) ->
		if not callback
			callback = fragment
			fragment = null

		return callback "filename null" if not filename
		if @content[filename]
			return callback null, @content[filename] if not fragment
			return callback null, @content[filename][fragment] if typeof fragment == 'string' and @content[filename][fragment]
			if fragment?.length > 0
				c = []
				for f in fragment
					c.push @content[filename][f] if @content[filename][f]
				return callback null, c

		@getContentRaw filename, (err, data) =>
			return callback 'No data in ' + filename if err or not data

			if @getExtension(filename) == 'md'
				data = @compile data

			@content[filename] = data

			if fragment
				return callback null, data[fragment] if typeof fragment == 'string' and data[fragment]
				if fragment.length > 0
					c = []
					for f in fragment
						c.push data[f] if data[f]
					return callback null, c

			return callback null, data

	serve: (options) ->
		p = path.normalize(options.directory).replace `/\\/g`, '/'
		@owner = options.owner
		@repo = options.repo
		@mode = options.mode
		@username = options.user || options.username
		@password = options.pass || options.password

		return (req, res, next) =>
			file = path.normalize(path.join(options.directory, req.path())).replace `/\\/g`, '/'

			if req.method != 'GET' && req.method != 'HEAD'
				next new restify.MethodNotAllowedError(req.method)
				return

			if file.substr(0, p.length) != p
				next new restify.NotAuthorizedError(req.path())
				return

			fs.readFile file, 'utf8', (err, data) =>
				results = data.match `/\[\[\s?include ([a-zA-Z0-9-_.\/]+)(\#([a-zA-Z0-9-_.]+))?\s?\]\]/gi`

				if results
					m = []
					includes = {}
					files = []
					for u in results
						do (u) =>
							arr = u.match(`/\[\[\s?include ([a-zA-Z0-9-_.\/]+)(\#([a-zA-Z0-9-_.]+))?\s?\]\]/i`)

							if not includes[arr[1]]
								includes[arr[1]] = []
								files.push arr[1]
							includes[arr[1]].push arr[3]

					for f in files
						m.push (callback) => @getContent f, includes[f], callback

					async.parallel m, (err, contents) =>
						tmp = []
						for i in contents
							if typeof i !=  'string' && i.length > 0
								tmp = tmp.concat i
							else if typeof i == 'string'
								tmp.push i

						contents = tmp

						i = 0
						for u in results
							data = data.replace(u, contents[i++])

						res.setHeader 'Content-Type', 'text/html'
						res.send data
						return next()


				else
					res.setHeader 'Content-Type', 'text/html'
					res.send data
					return next()

	fetch: (slug) ->

module.exports = new Content()