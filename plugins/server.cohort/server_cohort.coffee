Url = require 'url'

exports.setup = (callback) ->

	emitCohort = (step, user, now) =>
		@emit 'cohort.' + step, user, now

	setDate = (step, user) =>
		@db.redis.get 'u:' + user.id + ':date_' + step, (e, r) =>
			return if e or r
			now = (new Date).getTime()
			@db.redis.set 'u:' + user.id + ':date_' + step, now, (->)
			emitCohort step, user, now

	@on 'user.register', (user) =>
		emitCohort 'inscr', user, (new Date).getTime()

	@on 'user.validate', (user) =>
		emitCohort 'validate', user, (new Date).getTime()

	@on 'connect.callback', (data) =>
		return if data.status != 'success'
		@db.redis.hget 'a:keys', data.key, (e, idapp) =>
			return if e or not idapp
			@db.redis.get 'a:' + idapp + ':owner', (e, iduser) =>
				return if e or not iduser

				user = id:iduser

				# cohort analysis: activation check
				setDate 'activation', user

				# cohort analysis: development check
				origin = data.origin
				domain = Url.parse origin
				if not domain.protocol
					origin = 'http://' + origin
					domain = Url.parse origin
				if domain.host != @config.url.host
					setDate 'development', user

				# cohort analysis: production
				if not origin.match /local/
					@db.redis.incr 'u:' + iduser + ':ext_authcount', (e, r) =>
						return if e or r < 50
						setDate 'production', user

	@on 'user.pay', (data) =>
		setDate 'consumer', data.user.profile

	@on 'user.update_nbapps', (user, nb) =>
		setDate 'ready', user if nb >= 2

	@on 'user.update_nbproviders', (user, nb) =>
		setDate 'ready', user if nb >= 2

	#@on 'user.update_nbauth', (user, month, nb) =>
		#setDate 'ready', user if nb >= 10000 # todo: per user

	callback()