testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
env = {}
describe 'Data - db module', () ->
	logs = []
	beforeEach () ->
		env = {
			mode: 'test'
		}

		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		dataModule(env)
		logs = []
		env.debug = () ->
			logs.push(arguments)

	xit 'uid generation - env.data.generateUid', (done) ->
		done()

	xit 'hash generation - env.data.generateHash', (done) ->
		done()

	xit 'empty string generation - env.data.emptyStrIfNull', (done) ->
		done()


