Path = require "path"

testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
env = {}

logs = []
describe 'Data - providers module', () ->
	beforeEach () ->
		env = {
			mode: 'test'
		}

		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		dataModule(env)

		env.debug = () ->
			logs.push(arguments)
		logs = []

	it 'Provider list retrieval - env.data.providers.getList', (done) ->
		expect(env.data.providers.getList).toBeDefined()
		expect(typeof env.data.providers.getList).toBe("function")

		env.data.providers.getList (err, list) ->
			expect(err).toBeNull()
			expect(list).toBeDefined()
			expect(Array.isArray(list)).toBe(true)
			if list.length > 0
				expect(list[0].provider).toBeDefined()
				expect(list[0].provider).not.toBeNull()
				expect(list[0].name).toBeDefined()
				expect(list[0].name).not.toBeNull()
			done()

	it 'Provider retrieval - env.data.providers.get', (done) ->
		# to mock fs - not working yet :(
		# providers_dir = env.config.rootdir + '/providers'
		# provider_name = "myProvider"
		# provider_folder = Path.resolve providers_dir, provider_name
		# provider = Path.resolve providers_dir, provider_name + '/conf.json'
		
		env.data.providers.get "undefined_provider", (err, conf) ->
			expect(err).toBeDefined()
			expect(err).not.toBeNull()
			expect(conf).toBeUndefined()
			env.data.providers.get "facebook", (err, conf) ->
				expect(err).toBeNull()
				expect(conf).toBeDefined()
				done()

	xit 'Provider settings retrieval - env.data.providers.getSettings', (done) ->
		done()

	xit 'Provider /me mappings - env.data.providers.getMeMapping', (done) ->
		done()

	xit 'Provider extended description retrieval - env.data.providers.getExtended', (done) ->
		done()
