testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
env = {}
describe 'Data - states module', () ->
	logs = []
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

	xit 'State creation - env.data.states.add', (done) ->
		done()

	xit 'State info retrieval - env.data.states.get', (done) ->
		done()

	xit 'State info update - env.data.states.set', (done) ->
		done()

	xit 'State deletion - env.data.states.del', (done) ->
		done()

	xit 'State token set - env.data.states.setToken', (done) ->
		done()