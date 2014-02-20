module.exports = (req, res, next) ->
	console.log 'Entered proxy mode'
	console.log 'params', req.params
	console.log 'body', req.body
	console.log 'hello'