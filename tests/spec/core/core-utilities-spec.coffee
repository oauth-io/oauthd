testConfig = require '../../test-config'
coreModule = require testConfig.project_root + '/src/core'

async = require 'async'

describe 'Core - env.utilities module', () ->
	env = {}
	beforeEach () ->
		env = {}
		coreModule(env).initEnv()
		coreModule(env).initConfig()
		coreModule(env).initUtilities()

	it 'env.utilities.check with format.key (success case)', (done) ->
		method = env.utilities.check env.utilities.check.format.key, (key, callback) ->
			callback(null, 'hello')
		method 'azb-5_78901234567890123456', (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	# key

	it 'env.utilities.check with format.key (error cases)', (done) ->
		async.series [
			# string too big
			(next) ->
				method = env.utilities.check env.utilities.check.format.key, (key, callback) ->
					callback(null, 'hello')
				method '1234567890123456789012345689', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
			# string too small
			(next) ->
				method = env.utilities.check env.utilities.check.format.key, (key, callback) ->
					callback(null, 'hello')
				method '1234567890123456789012', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
			# forbidden chars
			(next) ->
				method = env.utilities.check env.utilities.check.format.key, (key, callback) ->
					callback(null, 'hello')
				method '12#456789012345678901$123', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()
		

	# mail

	it 'env.utilities.check with format.mail (success case)', (done) ->
		method = env.utilities.check env.utilities.check.format.mail, (mail, callback) ->
			callback(null, 'hello')
		method 'someaddress@someserver.com', (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with format.mail (error cases)', (done) ->
		async.series [
			# not a mail
			(next) ->
				method = env.utilities.check env.utilities.check.format.mail, (mail, callback) ->
					callback(null, 'hello')
				method 'somestring@bla#.com', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# provider name

	it 'env.utilities.check with format.provider (success case)', (done) ->
		method = env.utilities.check env.utilities.check.format.provider, (checked_v, callback) ->
			callback(null, 'hello')
		method 'provider-name', (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with format.provider (error cases)', (done) ->
		async.series [
			# too small a string
			(next) ->
				method = env.utilities.check env.utilities.check.format.provider, (provider, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
			# forbidden characters
			(next) ->
				method = env.utilities.check env.utilities.check.format.provider, (provider, callback) ->
					callback(null, 'hello')
				method 'soblabla,', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# any

	it 'env.utilities.check with "any" (success case)', (done) ->
		method = env.utilities.check "any", (checked_v, callback) ->
			callback(null, 'hello')
		method 'something', (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "any" (error cases)', (done) ->
		async.series [
			# undefined
			(next) ->
				method = env.utilities.check 'any', (provider, callback) ->
					callback(null, 'hello')
				method undefined, (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# none

	it 'env.utilities.check with "none" (success case)', (done) ->
		method = env.utilities.check 'none', (checked_v, callback) ->
			callback(null, 'hello')
		method undefined, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "none" (error cases)', (done) ->
		async.series [
			# value given
			(next) ->
				method = env.utilities.check 'none', (provider, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# null

	it 'env.utilities.check with "null" (success case)', (done) ->
		method = env.utilities.check 'null', (checked_v, callback) ->
			callback(null, 'hello')
		method null, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "null" (error cases)', (done) ->
		async.series [
			# not null
			(next) ->
				method = env.utilities.check 'null', (provider, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# string

	it 'env.utilities.check with "string" (success case)', (done) ->
		method = env.utilities.check 'string', (checked_v, callback) ->
			callback(null, 'hello')
		method 'somestring', (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "string" (error cases)', (done) ->
		async.series [
			# too small a string
			(next) ->
				method = env.utilities.check 'string', (provider, callback) ->
					callback(null, 'hello')
				method 123, (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
			# forbidden characters
			(next) ->
				method = env.utilities.check env.utilities.check.format.provider, (provider, callback) ->
					callback(null, 'hello')
				method 'soblabla,', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()


	# regexp

	it 'env.utilities.check with "regexp" (success case)', (done) ->
		method = env.utilities.check "regexp", (checked_v, callback) ->
			callback(null, 'hello')
		method /someregexp/, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "regexp" (error cases)', (done) ->
		async.series [
			# Not a regexp
			(next) ->
				method = env.utilities.check 'regexp', (provider, callback) ->
					callback(null, 'hello')
				method 'notaregexp', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# object

	it 'env.utilities.check with "object" (success case)', (done) ->
		async.series [
			(next) ->
				method = env.utilities.check 'object', (checked_v, callback) ->
					callback(null, 'hello')
				method {some: 'object'}, (err, v) ->
					expect(err).toBeNull()
					expect(v).toBe('hello')
					next()
		], () ->
			done()

	it 'env.utilities.check with "object" (error cases)', (done) ->
		async.series [
			# not an object
			(next) ->
				method = env.utilities.check 'object', (cheked_v, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# function

	it 'env.utilities.check with "function" (success case)', (done) ->
		method = env.utilities.check 'function', (checked_v, callback) ->
			callback(null, 'hello')
		method (() -> return 'hello'), (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "function" (error cases)', (done) ->
		async.series [
			# not a function
			(next) ->
				method = env.utilities.check 'function', (cheked_v, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# array

	it 'env.utilities.check with "array" (success case)', (done) ->
		method = env.utilities.check 'array', (checked_v, callback) ->
			callback(null, 'hello')
		method ['some', 'array'], (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "array" (error cases)', (done) ->
		async.series [
			# not an array
			(next) ->
				method = env.utilities.check 'array', (cheked_v, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# number

	it 'env.utilities.check with "number" (success case)', (done) ->
		method = env.utilities.check 'number', (checked_v, callback) ->
			callback(null, 'hello')
		method 1.435, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "number" (error cases)', (done) ->
		async.series [
			# not a number
			(next) ->
				method = env.utilities.check 'number', (cheked_v, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# int

	it 'env.utilities.check with "int" (success case)', (done) ->
		method = env.utilities.check 'int', (checked_v, callback) ->
			callback(null, 'hello')
		method 1, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "int" (error cases)', (done) ->
		async.series [
			# not an int
			(next) ->
				method = env.utilities.check 'int', (cheked_v, callback) ->
					callback(null, 'hello')
				method 1.423, (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# bool

	it 'env.utilities.check with "bool" (success case)', (done) ->
		method = env.utilities.check 'bool', (checked_v, callback) ->
			callback(null, 'hello')
		method true, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "bool" (error cases)', (done) ->
		async.series [
			# not a boolean
			(next) ->
				method = env.utilities.check 'bool', (cheked_v, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# date

	it 'env.utilities.check with "date" (success case)', (done) ->
		method = env.utilities.check 'date', (checked_v, callback) ->
			callback(null, 'hello')
		method new Date(), (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with "date" (error cases)', (done) ->
		async.series [
			# not a date
			(next) ->
				method = env.utilities.check 'date', (cheked_v, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()

	# several args

	it 'env.utilities.check with several arguments (success case)', (done) ->
		method = env.utilities.check 'int', 'object', (checked_v, object, callback) ->
			callback(null, 'hello')
		method 3, { some: 'object' }, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with several arguments (error cases)', (done) ->
		async.series [
			# wrong args
			(next) ->
				method = env.utilities.check 'int', 'object', (checked_v, object, callback) ->
					callback(null, 'hello')
				method 's', '', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
			# not right arg count
			(next) ->
				method = env.utilities.check 'int', 'object', (checked_v, object, callback) ->
					callback(null, 'hello')
				method 's', (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters count')
					next()
		], () ->
			done()

	# args in object

	it 'env.utilities.check with arguments in object (success case)', (done) ->
		method = env.utilities.check { hello: 'string', world: 'int'}, (checked_v, callback) ->
			callback(null, 'hello')
		method { hello: 'world', world: 4 }, (err, v) ->
			expect(err).toBeNull()
			expect(v).toBe('hello')
			done()

	it 'env.utilities.check with arguments in object (error cases)', (done) ->
		async.series [
			# wrong args
			(next) ->
				method = env.utilities.check { hello: 'string', world: 'int'}, (cheked_v, callback) ->
					callback(null, 'hello')
				method { lol: 'somestuff' }, (err, v) ->
					expect(err).not.toBeNull()
					expect(err.message).toBe('Bad parameters format')
					next()
		], () ->
			done()
