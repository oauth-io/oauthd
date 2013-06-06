# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

# to generate all symlinks from webshell (and show only errors), run
# coffee prov_logo.coffee > /dev/null

fs = require 'fs'
Url = require 'url'

symlink = (provider) ->
	fs.symlink '../../fs/bin/' + provider + '/logo.png', './providers/' + provider + '.png'

fs.readdir __dirname + '/providers', (err, files) ->
	for file in files
		file = file.substr(0,file.length-5)
		do (file) ->
			fs.exists __dirname + '/../fs/bin/' + file + '/v0.1/conf.json', (exists) ->
				if exists
					fs.exists __dirname + '/../fs/bin/' + file + '/logo.png', (exists) ->
						if exists
							symlink file if file
