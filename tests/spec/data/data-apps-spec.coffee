
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

	xit 'Application creation - env.data.apps.create', (done) ->
		expect(env.data.apps.create).toBeDefined()
		pending()

	xit 'Application retrieval by owner - env.data.apps.getByOwner', (done) ->
		done()


	xit 'Application retrieval by id - env.data.apps.get', (done) ->
		done()

	xit 'Application update by id - env.data.apps.get', (done) ->
		done()

	xit 'Application key reset - env.data.apps.get', (done) ->
		done()

	xit 'Application removal - env.data.apps.get', (done) ->
		done()

	xit 'Application domain update - env.data.apps.updateDomains', (done) ->
		done()

	xit 'Application domain add - env.data.apps.addDomain', (done) ->
		done()

	xit 'Application domain retrieval - env.data.apps.getDomains', (done) ->
		done()

	xit 'Application domain removal - env.data.apps.remDomain', (done) ->
		done()

	xit 'Application backend set - env.data.apps.setBackend', (done) ->
		done()

	xit 'Application backend check - env.data.apps.checkDomain', (done) ->
		done()

	xit 'Application owner retrieval - env.data.apps.getOwner', (done) ->
		done()

	xit 'Application secret check - env.data.apps.checkSecret', (done) ->
		done()
