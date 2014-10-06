testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'

describe 'Core - env.pluginsEngine module', () ->
	env = {}
	beforeEach () ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		coreModule(env).initPluginsEngine(process.cwd() + '/tests')

	it 'env.pluginsEngine.load should throw an exception if file doesn\'t exists', (done) ->
		logs = []
		env.debug = () ->
     		logs.push arguments
		try
			expect(env.pluginsEngine.load 'undefined_plugin')
		catch e
			console.log "err", e
		finally
			expect(logs[0][0]).toBe("Loading \'undefined_plugin\'.")
			expect(logs[1][0]).toBe("Absent plugin.json for plugin \'undefined_plugin\'.")
			expect(logs[2][0]).toBe("Error requiring plugin \'undefined_plugin\' entry point.")
			expect(env.pluginsEngine.plugin['undefined_plugin']).toBeUndefined()
			expect(env.plugins['undefined_plugin']).toBeUndefined()
			expect(env.plugins.undefined_plugin).toBeUndefined()
		done()

	it 'env.pluginsEngine.init outside of the \'instance_test\' folder should return err true and log', (done) ->
		logs = []
		env.debug = () ->
     		logs.push arguments
     	env.pluginsEngine.init process.cwd(), (err) ->
			expect(err).toBe(true)
			console.log "logs1", logs
			expect(logs[0][0]).toBe("An error occured: Error: ENOENT, open \'" + process.cwd() + "/plugins.json\'")
		done()

	it 'env.pluginsEngine.init inside of the \'instance_test\' folder should return err false', (done) ->
		logs = []
		env.debug = () ->
     		logs.push arguments
     	env.pluginsEngine.init process.cwd() + '/tests/instance_test', (err) ->
			expect(err).toBe(false)
			console.log "logs2", logs
			# Loading 'plugin_test'.
			# Error requiring plugin 'plugin_test' entry point.
		done()












