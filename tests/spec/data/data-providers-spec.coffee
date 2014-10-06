testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
env = {}
describe 'Data - providers module', () ->
	beforeEach () ->
		env = {
			mode: 'test'
		}

		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		dataModule(env)

	it 'Provider list retrieval - env.data.providers.getList', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Provider retrieval - env.data.providers.get', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Provider settings retrieval - env.data.providers.getSettings', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Provider /me mappings - env.data.providers.getMeMapping', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Provider extended description retrieval - env.data.providers.getExtended', (done) ->
		throw new Error('Test not implemented')
		done()