
testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'

describe 'Core - env.utilities module', () ->
	env = {}
	beforeEach () ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()

	# it 'env.utilities.check() should raise an error when called with wrong type', (done) ->
	# 	expect(false).toBe(true)
	# 	done()
	# 	