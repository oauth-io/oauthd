testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'
async = require 'async'

describe 'Data - apps module', () ->

	env = {
		mode: 'test'
	}
	
	uid = '0'
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

		env.data.generateUid = () ->
			return uid

	it 'Application creation - env.data.apps.create (success case)', (done) ->
		
		expect(env.data.apps.create).toBeDefined()
		uid = '-0'
		env.data.apps.create { name: 'myapp' }, { id: 1 }, (err, app) ->
			expect(err).toBe(null)
			expect(typeof app).toBe('object')
			expect(typeof app.id).toBe('number')
			expect(app.name).toBe('myapp')
			expect(app.key).toBe('-0')

			env.data.redis.mget [
				'a:' + app.id + ':name',
				'a:' + app.id + ':key',
				'a:' + app.id + ':secret',
				'a:' + app.id + ':owner',
				'a:' + app.id + ':date'
			],  (err, result) ->
				expect(err).toBe(null)
				expect(result[0]).toBe('myapp')
				expect(result[1]).toBe('-0')
				expect(result[2]).toBe('-0')
				expect(result[3]).toBe('1')
				expect(result[4]).toMatch(/^[0-9]+$/)

				env.data.redis.hget 'a:keys', '-0', (err, id) ->
					expect(id).toBe(app.id)
					done()

	it 'Application creation - env.data.apps.create (error cases)', (done) ->
		uid = '-0'

		async.series [
			(next) ->
				env.data.apps.create undefined, { id: 1 }, (err, app) ->
					expect(err).toBeDefined()
					expect(app).toBeUndefined()
					expect(err.message).toBe('You must specify a name and at least one domain for your application.')
					next()
			(next) ->
				env.data.apps.create {name:'myapp'}, undefined, (err, app) ->
					expect(err).toBeDefined()
					expect(app).toBeUndefined()
					expect(err.message).toBe('The user must be defined and contain the field \'id\'')
					next()
			(next) ->
				env.data.apps.create {name: undefined}, { id: 1 }, (err, app) ->
					expect(err).toBeDefined()
					expect(app).toBeUndefined()
					expect(err.message).toBe('You must specify a name and at least one domain for your application.')
					next()
			(next) ->
				env.data.apps.create {name:'myapp'}, {id: undefined}, (err, app) ->
					expect(err).toBeDefined()
					expect(app).toBeUndefined()
					expect(err.message).toBe('The user must be defined and contain the field \'id\'')
					next()
		], (err) ->
			done()

	it 'Application retrieval by owner - env.data.apps.getByOwner (success case)', (done) ->
		uid = '-1'
		env.data.apps.create {name:'myapp'}, { id: 5 }, (err, app) ->
			expect(err).toBeNull()
			env.data.apps.getByOwner 5, (err, apps) ->
				expect(err).toBeNull()
				app = apps[0]
				expect(typeof app).toBe('object')
				expect(app.name).toBe('myapp')
				expect(app.key).toBe('-1')
				expect(app.secret).toBe('-1')
				expect(app.owner).toBe('5')
				done()

	it 'Application retrieval by owner - env.data.apps.getByOwner (error cases)', (done) ->
		uid = '-1'
		env.data.apps.create {name:'myapp'}, { id: 6 }, (err, app) ->
			expect(err).toBeNull()
			env.data.apps.getByOwner 6, (err, apps) ->
				expect(apps.length).toBe(1)
				done()


	it 'Application retrieval by id - env.data.apps.getById', (done) ->
		uid = '-2'
		env.data.apps.create {name:'myapp'}, { id: 1 }, (err, app) ->
			expect(err).toBeNull()
			env.data.apps.getById app.id, (err, app2) ->
				expect(err).toBeNull()
				expect(typeof app2).toBe('object')
				expect(app2.name).toBe('myapp')
				expect(app2.owner).toBe('1')
				expect(app2.id).toBe(app.id)
				expect(app2.key).toBe('-2')
				expect(app2.secret).toBe('-2')
				done()

	it 'Application retrieval by key - env.data.apps.get (success case)', (done) ->
		uid = 'qwertyuiop1234567890asd'
		env.data.apps.create {name:'myapp'}, { id: 10 }, (err, app) ->
			expect(err).toBeNull()
			env.data.apps.get app.key, (err, app2) ->
				expect(err).toBeNull()
				expect(typeof app2).toBe('object')
				expect(app2.name).toBe('myapp')
				expect(app2.owner).toBe('10')
				expect(app2.id).toBe(app.id)
				expect(app2.key).toBe(uid)
				expect(app2.secret).toBe(uid)
				done()

	it 'Application key reset - env.data.apps.update (success case)', (done) ->
		uid = 'yahouyahouyahouyahouyahou'
		env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
			expect(err).toBeNull()
			env.data.apps.update app.key, { name: 'anothername' }, (err) ->
				expect(err).toBeUndefined()
				env.data.redis.get 'a:' + app.id + ':name', (err, name) ->
					expect(name).toBe('anothername')
					done()
		uid = '2ahouyahouyahouyahouyahou'
		env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
			expect(err).toBeNull()
			env.data.apps.update app.key, { domains: ['somedomain'] }, (err) ->
				expect(err).toBeUndefined()
				env.data.redis.smembers 'a:' + app.id + ':domains', (err, domains) ->
					expect(domains[0]).toBe('somedomain')
					done()


	it 'Application key reset - env.data.apps.update (error cases)', (done) ->
		# existing app with undefined
		uid = '3ahouyahouyahouyahouyahou'
		env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
			env.data.apps.update app.key, undefined, (err) ->
				expect(err).toBeDefined()
				expect(err.message).toBe('Bad parameters format')
				done()

		# unexisting app
		uid = '4ahouyahouyahouyahouyahou'
		env.data.apps.update uid, {name: 'hey'}, (err) ->
			expect(err).toBeDefined()
			expect(err.message).toBe('Unknown key')
			done()


	it 'Application key reset - env.data.apps.resetKey', (done) ->
		uid = '5testestestestestesteste'
		env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
			uid = 'newkeynewkeynewkeynewkey'
			env.data.apps.resetKey app.key, (err, result) ->
				expect(result.key).toBe(uid)
				expect(result.secret).toBe(uid)
				done()

	it 'Application removal - env.data.apps.remove (success case)', (done) ->
		uid = 'applicationremovaltesttes'
		env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
			env.data.apps.remove app.key, (err) ->
				expect(err).toBeUndefined()
				env.data.redis.keys 'a:' + app.id + '*', (err, keys) ->
					expect(keys.length).toBe(0)
					
					env.data.redis.hget 'a:keys', app.key, (err, id) ->
						expect(err).toBe(null)
						expect(id).toBe(null)
						done()

	it 'Application removal - env.data.apps.remove (error cases)', (done) ->
		uid = 'inexistingapplicationtest'
		env.data.apps.remove uid, (err) ->
			expect(err).toBeDefined()
			expect(err.message).toBe('Unknown key')
			done()

	it 'Application domain update - env.data.apps.updateDomains (success case)', (done) ->
		uid = 'appdomainupdatetestestest'
		env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
			env.data.apps.updateDomains app.key, ['domain1', 'domain2'], (err) ->
				expect(err).toBeUndefined()
				env.data.redis.smembers 'a:' + app.id + ':domains', (err, domains) ->
					expect(err).toBeNull()
					expect(domains.length).toBe(2)
					expect(domains[0]).toBe('domain1')
					expect(domains[1]).toBe('domain2')
					done()

	it 'Application domain update - env.data.apps.updateDomains (error cases)', (done) ->
		async.series [
			(next) ->
				# unknown key
				uid = 'inexistingapplicationtest'
				env.data.apps.updateDomains uid, ['domain1', 'domain2'], (err) ->
					expect(err).toBeDefined()
					expect(err.message).toBe('Unknown key')
					next()
			(next) ->
				# wrong argument type
				uid = 'appdomainupdateerrorstest'
				env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
					env.data.apps.updateDomains uid, undefined, (err) ->
						expect(err).toBeDefined()
						expect(err.message).toBe('Bad parameters format')
						next()		
		], () ->
			done()

	it 'Application domain add - env.data.apps.addDomain (success case)', (done) ->
		uid = 'appdomainaddadderrorstest'
		env.data.apps.create {name:'myapps'}, {id: 12}, (err, app) ->
			env.data.apps.addDomain app.key, 'somedomain', (err) ->
				expect(err).toBeUndefined()
				env.data.redis.smembers 'a:' + app.id + ':domains', (err, domains) ->
					expect(err).toBeNull()
					expect(domains.length).toBe(1)
					expect(domains[0]).toBe('somedomain')
					done()

	it 'Application domain add - env.data.apps.addDomain (error cases)', (done) ->
		async.series [
			(next) ->
				# unknown key
				uid = 'inexistingapplicationtest'
				env.data.apps.addDomain uid, 'domain1', (err) ->
					expect(err).toBeDefined()
					expect(err.message).toBe('Unknown key')
					next()
			(next) ->
				# wrong argument type
				uid = 'appdomainupdateerrorstest'
				env.data.apps.create {name:'myapp'}, { id: 12 }, (err, app) ->
					env.data.apps.addDomain uid, undefined, (err) ->
						expect(err).toBeDefined()
						expect(err.message).toBe('Bad parameters format')
						next()		
		], () ->
			done()

	it 'Application domain retrieval - env.data.apps.getDomains (success case)', (done) ->
		uid = 'appdomainretrievaltestestte'
		env.data.apps.create {name: 'myapp'}, {id: 12}, (err, app) ->
			env.data.apps.updateDomains app.key, ['domain1', 'domain2'], (err) ->
				env.data.apps.getDomains app.key, (err, domains) ->
					expect(err).toBeNull()
					expect(domains.length).toBe(2)
					expect(domains[0]).toBe('domain1')
					expect(domains[1]).toBe('domain2')
					done()

	it 'Application domain retrieval - env.data.apps.getDomains (error cases)', (done) ->
		uid = 'inexistingapplicationtest'
		env.data.apps.getDomains uid, (err, domains) ->
			expect(err).not.toBeNull()
			expect(err.message).toBe('Unknown key')
			done()

	it 'Application domain removal - env.data.apps.remDomain (success case)', (done) ->
		uid = 'appremovaltestesttestestte'
		env.data.apps.create {name: 'myapp', domains: ['hello', 'world']}, {id: 12}, (err, app) ->
			env.data.apps.remDomain app.key, 'hello', (err) ->
				expect(err).toBeUndefined()
				env.data.redis.smembers 'a:' + app.id + ':domains', (err, domains) ->
					expect(err).toBeNull()
					expect(domains.length).toBe(1)
					expect(domains[0]).toBe('world')
					done()

	it 'Application domain removal - env.data.apps.remDomain (error cases)', (done) ->
		async.series [
			(next) ->
				# unknown key
				uid = 'inexistingapplicationtest'
				env.data.apps.remDomain uid, 'domain1', (err) ->
					expect(err).toBeDefined()
					expect(err.message).toBe('Unknown key')
					next()
			(next) ->
				# wrong argument type
				uid = 'appremovalestesttestestte'
				env.data.apps.create {name: 'myapp', domains: ['hello', 'world']}, {id: 12}, (err, app) ->
					env.data.apps.remDomain app.key, 'hohoho', (err) ->
						expect(err).toBeDefined()
						expect(err.message).toBe('Invalid format')
						expect(err.body?.domain).toBe('hohoho is already non-valid')
						done()	
		], () ->
			done()

	it 'Application backend set - env.data.apps.setBackend (success case)', (done) ->
		uid = 'appbackendsettestesttes'
		env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
			env.data.apps.setBackend app.key, 'backend', {somekey: 'somevalue'}, (err) ->
				expect(err).toBeUndefined()
				env.data.redis.get 'a:' + app.id + ':backend:name', (err, name) ->
					expect(err).toBeNull()
					expect(name).toBe('backend')

					env.data.redis.get 'a:' + app.id + ':backend:value', (err, value) ->
						expect(err).toBeNull()
						try
							value = JSON.parse(value)
						catch error
							expect(error).toBeUndefined()
						finally
							expect(typeof value).toBe('object')
							expect(value.somekey).toBe('somevalue')
							done()

	it 'Application backend retrieval - env.data.apps.getBackend (success case)', (done) ->
		uid = 'appbackendgettestesttes'
		env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
			env.data.apps.setBackend app.key, 'backend', {somekey: 'somevalue'}, (err) ->
				env.data.apps.getBackend app.key, (err, backend) ->
					expect(err).toBeNull()
					expect(typeof backend).toBe('object')
					expect(backend.name).toBe('backend')
					expect(typeof backend.value).toBe('object')
					expect(backend.value.somekey).toBe('somevalue')
					done()

	it 'Application backend removal - env.data.apps.remBackend (success case)', (done) ->
		uid = 'appbackendrmttestesttes'
		env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
			env.data.apps.setBackend app.key, 'backend', {somekey: 'somevalue'}, (err) ->
				env.data.apps.remBackend app.key, (err) ->
					expect(err).toBeUndefined()
					env.data.redis.mget ['a:' + app.id + ':backend:name', 'a:' + app.id + ':backend:value'], (err, result) ->
						expect(err).toBeNull()
						expect(result[0]).toBeNull()
						expect(result[1]).toBeNull()
						done()
	

	it 'Application keyset add - env.data.apps.addKeyset (success case)', (done) ->
		uid = 'appkeysetaddttestesttes'
		env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
			env.data.apps.addKeyset app.key, 'someprovider', { parameters: { hello: 'world' } }, (err) ->
				expect(err).toBeUndefined()
				env.data.redis.get 'a:' + app.id + ':k:someprovider', (err, data) ->
					expect(err).toBeNull()
					try
						keyset = JSON.parse data
					catch error
						expect(error).toBeUndefined()
					finally
						expect(keyset.hello).toBe('world')
						done()


	it 'Application keysets retrieval - env.data.apps.getKeysets (success case)', (done) ->
		uid = 'appkeysetsgetttestesttes'
		env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
			env.data.apps.addKeyset app.key, 'someprovider', { parameters: { hello: 'world' } }, (err) ->
				expect(err).toBeUndefined()
				env.data.apps.getKeysets app.key, (err, keysets) ->
					expect(err).toBeNull()
					expect(keysets.length).toBe(1)
					expect(keysets[0]).toBe('someprovider')
					done()

	xit 'Application keyset removal - env.data.apps.remKeyset', (done) ->
		done()

	xit 'Application keyset retrieval with response type - env.data.apps.getKeysetWithResponseType', (done) ->
		done()

	it 'Application keyset retrieval with right response_types - env.data.apps.getKeysets (success case)', (done) ->
		async.series [
			(next) ->
				uid = 'appkeysetgettttestesttes'
				env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
					env.data.apps.addKeyset app.key, 'someprovider', { parameters: { hello: 'world' } }, (err) ->
						expect(err).toBeUndefined()
						env.data.apps.getKeyset app.key, 'someprovider', (err, keyset) ->
							expect(err).toBeNull()
							expect(keyset.parameters).toBeDefined()
							expect(keyset.parameters.hello).toBe('world')
							expect(keyset.response_type).toBe('token')
							next()
			(next) ->
				uid = 'appkeysetget2ttestesttes'
				env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
					env.data.apps.setBackend app.key, 'php', {}, (err) ->
						env.data.apps.addKeyset app.key, 'someprovider', { parameters: { hello: 'world' } }, (err) ->
							expect(err).toBeUndefined()
							env.data.apps.getKeyset app.key, 'someprovider', (err, keyset) ->
								expect(err).toBeNull()
								expect(keyset.parameters).toBeDefined()
								expect(keyset.parameters.hello).toBe('world')
								expect(keyset.response_type).toBe('code')
								next()
			(next) ->
				uid = 'appkeysetget3ttestesttes'
				env.data.apps.create {name: 'myapp'}, {id: 13}, (err, app) ->
					env.data.apps.setBackend app.key, 'php', { client_side: true }, (err) ->
						env.data.apps.addKeyset app.key, 'someprovider', { parameters: { hello: 'world' } }, (err) ->
							expect(err).toBeUndefined()
							env.data.apps.getKeyset app.key, 'someprovider', (err, keyset) ->
								expect(err).toBeNull()
								expect(keyset.parameters).toBeDefined()
								expect(keyset.parameters.hello).toBe('world')
								expect(keyset.response_type).toBe('both')
								next()

		], () ->
			done()
	
	xit 'Application domain verification - env.data.apps.checkDomain', (done) ->
		done()

	it 'Application owner retrieval - env.data.apps.getOwner', (done) ->
		uid = 'appownerretrievaltestest'
		env.data.apps.create {name: 'myapp'}, {id: 54}, (err, app) ->
			env.data.apps.getOwner app.key, (err, user) ->
				expect(err).toBeNull()
				expect(typeof user).toBe('object')
				expect(user.id).toBeDefined()
				expect(user.id).toBe(54)
				done()

	it 'Application secret check - env.data.apps.checkSecret (success case)', (done) ->
		uid = 'appsecretchecktestesteste'
		env.data.apps.create {name: 'myapp'}, { id: 55 }, (err, app) ->
			env.data.apps.checkSecret app.key, uid, (err, bool) ->
				expect(err).toBeNull()
				expect(bool).toBe(true)
				done()

	it 'Application secret check - env.data.apps.checkSecret (error cases)', (done) ->
		uid = 'appsecretchecktestesteste'
		uid2 = 'appsecretchecktestesseste'
		env.data.apps.create {name: 'myapp'}, { id: 55 }, (err, app) ->
			env.data.apps.checkSecret app.key, uid2, (err, bool) ->
				expect(err).toBeNull()
				expect(bool).toBe(false)
				done()
