testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
env = {}
describe 'Data - states module', () ->
	beforeEach () ->
		env = {
			mode: 'test'
		}

		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		dataModule(env)

	it 'State creation - env.data.states.add', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'State info retrieval - env.data.states.get', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'State info update - env.data.states.set', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'State deletion - env.data.states.del', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'State token set - env.data.states.setToken', (done) ->
		throw new Error('Test not implemented')
		done()