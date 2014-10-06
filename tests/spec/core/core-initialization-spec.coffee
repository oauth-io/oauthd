
testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
sugar = require 'sugar'

describe 'Core - env init', () ->

	# initEnv

	it 'coreModule(env).initEnv should initialize the env.events object', (done) ->
		env = {}
		coreModule(env).initEnv()
		expect(env.events).toBeDefined()
		expect(typeof env.events).toBe('object')
		done()

	it 'coreModule(env).initEnv should initialize the env.middlewares object, containing a \'always\' array', (done) ->
		env = {}
		coreModule(env).initEnv()
		expect(env.middlewares).toBeDefined()
		expect(typeof env.middlewares).toBe('object')
		expect(env.middlewares.always).toBeDefined()
		expect(typeof env.middlewares.always).toBe('object')
		expect(env.middlewares.always.length).toBeDefined()
		done()

describe 'Core - env.config init', () ->

	# initConfig

	it 'coreModule(env).initConfig should load the config.js file in env.config', (done) ->
		env = {}
		_config = require testConfig.project_root + '/config.js'
		coreModule(env).initConfig()
		for k,v of _config
			expect(env.config[k]).toBe(_config[k])
		done()


describe 'Core - utilities init', () ->

	# initUtilities

	it 'coreModule(env).initUtilities should init env.utilities', (done) ->
		env = {}
		coreModule(env).initUtilities()
		expect(env.utilities).toBeDefined()
		done()

	it 'env.utilities should contain check object', (done) ->
		env = {}
		coreModule(env).initUtilities()
		expect(env.utilities).toBeDefined()
		done()

	it 'env.utilities should contain exit object', (done) ->
		env = {}
		coreModule(env).initUtilities()
		expect(env.utilities.exit).toBeDefined()
		done()

	it 'env.utilities should contain formatters object', (done) ->
		env = {}
		coreModule(env).initUtilities()
		expect(env.utilities.formatters).toBeDefined()
		done()

	it 'env.utilities should contain logger object', (done) ->
		env = {}
		coreModule(env).initUtilities()
		expect(env.utilities.logger).toBeDefined()
		done()

	it 'env.utilities should contain mailer object', (done) ->
		env = {}
		coreModule(env).initUtilities()
		expect(env.utilities.mailer).toBeDefined()
		done()

describe 'Core - oauth init', () ->

	# initOAuth

	it 'coreModule(env).initOAuth should init env.utilities.oauth', (done) ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initUtilities()
		coreModule(env).initOAuth()
		expect(env.utilities.oauth).toBeDefined()
		done()

	it 'env.utilities.oauth should contain oauth1 object', (done) ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initUtilities()
		coreModule(env).initOAuth()
		expect(env.utilities.oauth.oauth1).toBeDefined()
		done()

	it 'env.utilities.oauth should contain oauth2 object', (done) ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initUtilities()
		coreModule(env).initOAuth()
		expect(env.utilities.oauth.oauth2).toBeDefined()
		done()


describe 'Core - pluginsEngine init', () ->

	# pluginsEngine

	it 'coreModule(env).initPluginsEngine should init env.pluginsEngine', (done) ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initUtilities()
		env.debug = () ->
			return
		coreModule(env).initPluginsEngine()
		expect(env.pluginsEngine).toBeDefined()
		done()

	it 'coreModule(env).initPluginsEngine should init env.pluginsEngine', (done) ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initUtilities()

		env.debug = () ->
			return

		coreModule(env).initPluginsEngine()
		expect(env.pluginsEngine).toBeDefined()
		expect(env.plugins).toBeDefined()
		expect(env.plugins).toEqual(jasmine.any(Object))
		expect(env.pluginsEngine.load).toEqual(jasmine.any(Function))
		expect(env.pluginsEngine.init).toEqual(jasmine.any(Function))
		expect(env.pluginsEngine.list).toEqual(jasmine.any(Function))
		expect(env.pluginsEngine.run).toEqual(jasmine.any(Function))
		expect(env.pluginsEngine.runSync).toEqual(jasmine.any(Function))
		done()
