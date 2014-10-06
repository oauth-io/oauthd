testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'

describe 'Core - env.pluginsEngine module', () ->
	env = {}
	beforeEach () ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		coreModule(env).initPluginsEngine()

	# it 'env.pluginsEngine.init should throw an exception if file doesn\'t exists', (done) ->
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
			console.log "process.cwd()", process.cwd()
		done()