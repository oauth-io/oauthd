
module.exports = (env) ->
    debug = () ->
    	console.log.apply this, arguments
    return debug