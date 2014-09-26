module.exports = (env) ->
	oauth1: require('./oauth1') env
	oauth2: require('./oauth2') env
	