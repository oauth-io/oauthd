mockfs = require('mock-fs')
testConfig = require '../../../test-config'
sugar = require 'sugar'
rewire = require 'rewire'
fs = require 'fs'
async = require 'async'
ncp = require 'ncp'
Q = require 'q'



describe 'Scaffolding - plugins - base', () ->
	scaffolding = undefined
	env = undefined

	exec_callback = (command, callback) ->
		callback null, '', ''
	ncp_callback = (opath, dpath, callback) ->
		ncp.apply null, arguments
		callback()

	beforeEach () ->
		env = {}
		scaffolding = rewire(testConfig.project_root + '/src/scaffolding')

		scaffolding.__set__ 'exec', (command, callback) ->
			exec_callback.apply null, arguments

		scaffolding = scaffolding(env)

		mocked = {
			'src': {
				'scaffolding': {
					'templates': {
						'plugin': {
							'plugin.json': JSON.stringify {
								name: 'plugin_test'
							}
						}
					}
				}
			}
		}

		mocked[process.cwd() + '/plugins'] = {
			'fakeplugin': {
				'plugin.json': JSON.stringify {
					name: 'fakeplugin',
					stuff: 'bla'
				}
			},
		}

		mocked[process.cwd() + '/plugins.json'] = JSON.stringify {
			'fakeplugin': 'somegit#1.2.3',
			'otherplugin': ''
		}

		mockfs mocked



	afterEach () ->
		mockfs.restore()

	readPluginsJson = (callback) ->
		fs.readFile process.cwd() + '/plugins.json', {encoding: 'UTF-8'}, (err, data) ->
			return callback err if err
			try
				pluginsjson = JSON.parse data
				callback null, pluginsjson
			catch e
				callback e
	readPluginJson = (plugin_name, callback) ->
		fs.readFile process.cwd() + '/plugins/' + plugin_name + '/plugin.json', { encoding: 'UTF-8' }, (err, data) ->
			return callback err if err
			try
				pluginjson = JSON.parse data
				callback null, pluginjson
			catch e
				callback e

	# Disable these tests until mock-fs can deal with coffee's sourcemap stuff
	###
	it 'scaffolding.plugins.create should create a folder containing the default structure', (done) ->
		scaffolding.plugins.create 'bla', true, true
			.then () ->
				async.parallel [
					(next) ->
						readPluginsJson (err, pluginsjson) ->
							expect(err).toBeNull()
							expect(pluginsjson['bla']).toBeDefined()
							expect(pluginsjson['bla'].active).toBe(true)
							next()

					(next) ->
						readPluginJson 'bla', (err, pluginjson) ->
							expect(pluginjson.name).toBe('bla')
							next()
				], () ->
					done()
			.fail (e) ->
				console.error(e)
				done()

	it 'scaffolding.plugins.create should not work if the folder already exists', (done) ->
		scaffolding.plugins.create 'fakeplugin', false, true
			.then () ->
				expect(true).toBeFalse()
				done()
			.fail (e) ->
				expect(e.message).toBeDefined()
				done()

	it 'scaffolding.plugins.create should work if the folder already exists and called with force', (done) ->
		scaffolding.plugins.create 'fakeplugin', true, true
			.then () ->
				async.parallel [
					(next) ->
						readPluginsJson (err, obj) ->
							expect(err).toBe(null)
							expect(obj['fakeplugin']).toBe('somegit#1.2.3')
							next()
					(next) ->
						readPluginJson 'fakeplugin', (err, obj) ->
							expect(err).toBe(null)
							expect(obj.stuff).toBeUndefined()
							next()
				], () ->
					done()
			.fail (e) ->
				expect(e).toBeDefined()
				done()

	it 'scaffolding.plugins.create should not create a plugins.json entry if save is false', (done) ->
		scaffolding.plugins.create 'blo', true, false
			.then () ->
				async.parallel [
					(next) ->
						readPluginsJson (err, obj) ->
							expect(err).toBe(null)
							expect(obj['blo']).toBeUndefined()
							next()
					(next) ->
						readPluginJson 'blo', (err, obj) ->
							expect(err).toBe(null)
							expect(obj.name).toBe('blo')
							next()
				], () ->
					done()
			.fail (e) ->
				expect(e).toBeDefined()
				done()
	###