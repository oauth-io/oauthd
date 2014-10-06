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

	it 'env.pluginsEngine.init outside of the \'instance_test\' folder should failed', (done) ->
		logs = []
		env.debug = () ->
			logs.push arguments
		env.pluginsEngine.init process.cwd(), (err) ->
			expect(err).toBe(true)
			expect(logs[0][0]).toBe("An error occured: Error: ENOENT, open \'" + process.cwd() + "/plugins.json\'")
			done()

	it 'env.pluginsEngine.init inside of the \'instance_test\' folder should fail on requiring \'plugin_test\' entry point', (done) ->
		logs = []
		env.debug = () ->
			logs.push arguments
		command = 'rm -rf ' + process.cwd() + '/tests/instance_test/plugins/plugin_test/bin'
		exec = require('child_process').exec
		exec command, (error, stdout, stderr) ->
			expect(error).toBeNull()
			env.pluginsEngine.init process.cwd() + '/tests/instance_test', (err) ->
				expect(err).toBe(false)
				expect(logs[0][0]).toBe("Loading \'plugin_test\'.")
				expect(logs[1][0]).toBe("Error requiring plugin \'plugin_test\' entry point.")
				done()

	it 'env.pluginsEngine.init inside of the \'instance_test\' folder should succeed after grunt in the folder', (done) ->
		logs = []
		env.debug = () ->
			logs.push arguments
		command = 'cd ' + process.cwd() + '/tests/instance_test/plugins/plugin_test && npm install && grunt'
		exec = require('child_process').exec
		exec command, (error, stdout, stderr) ->
			expect(error).toBeNull()
			if not error
				env.pluginsEngine.init process.cwd() + '/tests/instance_test', (err) ->
					expect(err).toBe(false)
					expect(logs[0][0]).toBe("Loading \'plugin_test\'.")
					expect(env.pluginsEngine.plugin['plugin_test']).toBeDefined()
					expect(env.pluginsEngine.plugin['plugin_test'].getMyName()).toBe("plugin_test")
					command = 'rm -rf ' + process.cwd() + '/tests/instance_test/plugins/plugin_test/bin'
					exec = require('child_process').exec
					exec command, (error, stdout, stderr) ->
						expect(error).toBeNull()
						done()

	it 'env.pluginsEngine.load should throw an exception when loading unexisting \'undefined_plugin\'.', (done) ->
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










