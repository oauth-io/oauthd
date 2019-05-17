
testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'
dataModule = require testConfig.project_root + '/src/data'

describe 'Data - Entity module', () ->
	User = undefined
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

		env.debug = () ->
			# logs.push(arguments)

		class UserClass extends env.data.Entity
			@prefix: 'testuser'
			@incr: 'testuser:i'

		User = UserClass


	it 'Creating a new entity', (done) ->
		user = new User()

		expect(typeof user.props).toBe('object')

		done()

	it 'Saving identities and incremental ids', (done) ->
		user = new User()

		user.props.name = 'Jérome Dupont'
		user.props.email = 'jerome@dupont.com'

		user.save()
			.then () ->
				expect(typeof user.id).toBe('number')


				user2 = new User()

				user2.props.name = 'Leo'

				user2.save()
					.then () ->
						expect(user2.id).toBe(user.id + 1)

						env.data.redis.get 'testuser:2:name', (err, name) ->
							expect(name).toBe('Leo')
							done()
			.fail (e) ->
				expect(e).toBeUndefined()
				done()





	it 'Updating a saved entity', (done) ->
		user = new User()

		user.props.name = 'Jérome Dupont'
		user.props.email = 'jerome@dupont.com'

		user.save()
			.then () ->
				user2 = new User(user.id)
				user2.load()
					.then () ->
						expect(user2.props.name).toBe('Jérome Dupont')
						expect(user2.props.email).toBe('jerome@dupont.com')
						user2.props.name = 'Jarome'
						user2.save()
							.then () ->
								env.data.redis.get 'testuser:' + user2.id + ':name', (err, name) ->
									expect(name).toBe('Jarome')
									done()


	it 'Deleting an entity', (done) ->
		user = new User()

		user.props.name = 'Jérome'
		user.props.email = 'jerome@dupont.com'

		user.save()
			.then () ->
				env.data.redis.keys 'testuser:' + user.id + '*', (err, keys1) ->
					expect(keys1.length).toBe(2)
					user.remove()
						.then () ->
							env.data.redis.keys 'testuser:' + user.id + '*', (err, keys2) ->
								expect(keys2.length).toBe(0)
								done()
