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

	xit 'Provider list retrieval - env.data.providers.getList', (done) ->
		done()

	xit 'Provider retrieval - env.data.providers.get', (done) ->
		done()

	xit 'Provider settings retrieval - env.data.providers.getSettings', (done) ->
		done()

	xit 'Provider /me mappings - env.data.providers.getMeMapping', (done) ->
		done()

	xit 'Provider extended description retrieval - env.data.providers.getExtended', (done) ->
		done()