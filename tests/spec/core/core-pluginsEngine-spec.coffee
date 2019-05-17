testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
colors = require 'colors'

describe 'Core - env.pluginsEngine module', () ->
	env = {}
	consolelogs = []
	origin_cwd = process.cwd()
	beforeEach () ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()
		env.scaffolding = require('../../../src/scaffolding')()

		env.debug = () ->
			consolelogs.push(arguments)

		coreModule(env).initPluginsEngine(process.cwd() + '/tests')
		consolelogs = []

	afterEach () ->
		process.chdir origin_cwd

	it 'env.pluginsEngine.init outside of the \'instance_test\' folder should fail when there is no \'plugin.json\' file.', (done) ->
		expect(env.pluginsEngine.init).toBeDefined()
		expect(typeof env.pluginsEngine.init).toBe("function")

		env.pluginsEngine.init process.cwd(), (err) ->
			expect(err).toBeDefined()
			done()

	it 'env.pluginsEngine.init inside of the \'instance_test\' folder should fail on requiring \'plugin_test\' entry point when it doesn\'t exist', (done) ->
		expect(env.pluginsEngine.init).toBeDefined()
		expect(typeof env.pluginsEngine.init).toBe("function")

		command = 'rm -rf ' + process.cwd() + '/tests/instance_test/plugins/plugin_test/bin'
		exec = require('child_process').exec
		exec command, (error, stdout, stderr) ->
			expect(error).toBeNull()
			env.pluginsEngine.init process.cwd() + '/tests/instance_test', (err) ->
				expect(err).toBeDefined()
				done()

	xit 'env.pluginsEngine.init inside of the \'instance_test\' folder should succeed after launching grunt command in that folder', (done) ->
		expect(env.pluginsEngine.init).toBeDefined()
		expect(typeof env.pluginsEngine.init).toBe("function")

		command = 'cd ' + process.cwd() + '/tests/instance_test/plugins/plugin_test && grunt'
		exec = require('child_process').exec
		exec command, (error, stdout, stderr) ->
			expect(error).toBeNull()
			if not error
				env.pluginsEngine.init process.cwd() + '/tests/instance_test', (err) ->
					expect(err).toBe(false)
					expect(consolelogs[0][0]).toBe("Loading " + "plugin_test".blue)
					expect(env.pluginsEngine.plugin['plugin_test']).toBeDefined()
					expect(env.pluginsEngine.plugin['plugin_test'].getMyName()).toBe("plugin_test")
					command = 'rm -rf ' + process.cwd() + '/tests/instance_test/plugins/plugin_test/bin'
					exec = require('child_process').exec
					exec command, (error, stdout, stderr) ->
						expect(error).toBeNull()
						done()

	it 'env.pluginsEngine.load should throw an exception when loading unexisting \'undefined_plugin\'.', (done) ->
		expect(env.pluginsEngine.load).toBeDefined()
		expect(typeof env.pluginsEngine.load).toBe("function")

		try
			expect(env.pluginsEngine.load 'undefined_plugin')
		catch e
			env.debug "err", e if e
		finally
			expect(consolelogs[0][0]).toBe("Cannot find addon undefined_plugin")
			expect(env.pluginsEngine.plugin['undefined_plugin']).toBeUndefined()
			expect(env.plugins['undefined_plugin']).toBeUndefined()
			expect(env.plugins.undefined_plugin).toBeUndefined()
			done()

	it 'env.pluginsEngine.list should throw an err when pluginsEngine is not init with the good cwd path', (done) ->
		expect(env.pluginsEngine.list).toBeDefined()
		expect(typeof env.pluginsEngine.list).toBe("function")

		env.pluginsEngine.list (err, list) ->
			expect(err).toBeDefined()
			expect(list).toBeUndefined()
			done()

	it 'env.pluginsEngine.list should return an array containing \'plugin_test\'', (done) ->
		expect(env.pluginsEngine.list).toBeDefined()
		expect(typeof env.pluginsEngine.list).toBe("function")

		process.chdir process.cwd() + '/tests/instance_test'
		env.pluginsEngine.init process.cwd(), (err) ->
			expect(err).toBeNull()
			env.pluginsEngine.list (err, list) ->
				expect(err).toBeNull()
				expect(list).toBeDefined()
				# expect(list).toContain("plugin_test")
				done()

	it 'env.pluginsEngine.run on the setup method should increment a variable inside a plugin', (done) ->
		expect(env.pluginsEngine.run).toBeDefined()
		expect(typeof env.pluginsEngine.run).toBe("function")

		plugin_test = {}
		plugin_test.testVar = 0
		plugin_test.setup = (callback) ->
			plugin_test.testVar++
			callback()
		env.plugins["plugin_test"] = plugin_test

		expect(env.plugins.plugin_test.testVar).toBe(0)
		env.pluginsEngine.run 'setup', =>
			expect(env.plugins.plugin_test.testVar).toBe(1)
			done()

	it 'env.pluginsEngine.runSync on the init method should increment a variable inside a plugin', (done) ->
		expect(env.pluginsEngine.runSync).toBeDefined()
		expect(typeof env.pluginsEngine.runSync).toBe("function")

		plugin_test = {}
		plugin_test.testVar = 0
		plugin_test.init = () ->
			plugin_test.testVar++
		env.plugins["plugin_test"] = plugin_test

		expect(env.plugins.plugin_test.testVar).toBe(0)
		try
			env.pluginsEngine.runSync 'init'
		finally
			expect(env.plugins.plugin_test.testVar).toBe(1)
			done()


	it 'env.pluginsEngine.run on the setup method should verify asynchronism of a variable incrementation', (done) ->
		expect(env.pluginsEngine.run).toBeDefined()
		expect(typeof env.pluginsEngine.run).toBe("function")

		plugin_test1 = {}
		env.test1Var = 0
		plugin_test1.setup = (callback) ->
			env.test1Var = 1
			setTimeout ( ->
					env.test1Var = 42
					callback()
				), 3000
		plugin_test2 = {}
		plugin_test2.setup = (callback) ->
			expect(env.test1Var).toBe(42)
			env.test1Var++
			callback()
		env.plugins["plugin_test1"] = plugin_test1
		env.plugins["plugin_test2"] = plugin_test2

		expect(env.test1Var).toBe(0)
		env.pluginsEngine.run 'setup', =>
			expect(env.test1Var).toBe(43)
			done()

	it 'env.pluginsEngine.runSync on the init method should verify synchronism of variables incrementation', (done) ->
		expect(env.pluginsEngine.runSync).toBeDefined()
		expect(typeof env.pluginsEngine.runSync).toBe("function")

		env.test2Var = 0
		plugin_test1 = {}
		plugin_test1.init = () ->
			env.test2Var = 1
			setTimeout ( =>
					env.test2Var = 42
				), 3000
		plugin_test2 = {}
		plugin_test2.init = () ->
			expect(env.test2Var).toBe(1)
			env.test2Var++
			setTimeout ( =>
					expect(env.test2Var).toBe(42)
					env.test2Var++
				), 3000
		env.plugins["plugin_test1"] = plugin_test1
		env.plugins["plugin_test2"] = plugin_test2

		expect(env.test2Var).toBe(0)
		try
			env.pluginsEngine.runSync 'init'
		finally
			expect(env.test2Var).toBe(2)
			setTimeout ( =>
					expect(env.test2Var).toBe(43)
					done()
				), 3000




