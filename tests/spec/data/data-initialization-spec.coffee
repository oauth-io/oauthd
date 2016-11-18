
testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
env = {}
describe 'Data - initialization', () ->
	beforeEach () ->
		env = {
			mode: 'test'
		}

		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()

		env.debug = () ->
			#logs.push(arguments)



	it 'dataModule() should initialize env.data', (done) ->
		dataModule(env)

		expect(env.data).toBeDefined()
		done()

	it 'dataModule() should initialize env.data.redis', (done) ->
		dataModule(env)

		expect(env.data.redis).toBeDefined()
		expect(typeof env.data.redis).toBe('object')
		done()

	it 'dataModule() should initialize env.data.generateUid', (done) ->
		dataModule(env)

		expect(env.data.generateUid).toBeDefined()
		expect(typeof env.data.generateUid).toBe('function')
		done()

	it 'dataModule() should initialize env.data.generateHash', (done) ->
		dataModule(env)

		expect(env.data.generateHash).toBeDefined()
		expect(typeof env.data.generateHash).toBe('function')
		done()

	it 'dataModule() should initialize env.data.generateHash', (done) ->
		dataModule(env)

		expect(env.data.generateHash).toBeDefined()
		expect(typeof env.data.generateHash).toBe('function')
		done()

	it 'dataModule() should initialize env.data.apps', (done) ->
		dataModule(env)

		expect(env.data.apps).toBeDefined()
		expect(typeof env.data.apps).toBe('object')
		done()

	it 'dataModule() should initialize env.data.providers', (done) ->
		dataModule(env)

		expect(env.data.providers).toBeDefined()
		expect(typeof env.data.providers).toBe('object')
		done()

	it 'dataModule() should initialize env.data.states', (done) ->
		dataModule(env)

		expect(env.data.states).toBeDefined()
		expect(typeof env.data.states).toBe('object')
		done()


	it 'dataModule() should initialize env.data.Entity', (done) ->
		dataModule(env)

		expect(env.data.Entity).toBeDefined()
		expect(typeof env.data.Entity).toBe('function')
		done()



