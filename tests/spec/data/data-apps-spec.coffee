
testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'

describe 'Data - apps module', () ->

	env = {
		mode: 'test'
	}
	beforeEach () ->
		env = {
			mode: 'test'
		}
		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		dataModule(env)

	it 'Application creation - env.data.apps.create', (done) ->
		expect(env.data.apps.create).toBeDefined()
		throw new Error('Test not implemented')
		done()

	it 'Application retrieval by owner - env.data.apps.getByOwner', (done) ->
		throw new Error('Test not implemented')
		done()


	it 'Application retrieval by id - env.data.apps.get', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application update by id - env.data.apps.get', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application key reset - env.data.apps.get', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application removal - env.data.apps.get', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application domain update - env.data.apps.updateDomains', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application domain add - env.data.apps.addDomain', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application domain retrieval - env.data.apps.getDomains', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application domain removal - env.data.apps.remDomain', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application backend set - env.data.apps.setBackend', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application backend check - env.data.apps.checkDomain', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application owner retrieval - env.data.apps.getOwner', (done) ->
		throw new Error('Test not implemented')
		done()

	it 'Application secret check - env.data.apps.checkSecret', (done) ->
		throw new Error('Test not implemented')
		done()
