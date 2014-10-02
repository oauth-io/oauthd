
testConfig = require '../test-config'
coreModule = require testConfig.project_root + '/src/core'

describe 'Core module - env init', () ->

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

describe 'Core module - env.config init', () ->

	# initConfig

	it 'coreModule(env).initConfig should load the config.js file in env.config', (done) ->
		env = {}
		_config = require testConfig.project_root + '/config.js'
		coreModule(env).initConfig()
		for k,v of _config
			expect(env.config[k]).toBe(_config[k])
		done()


describe 'Core module - utilities init', () ->

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


