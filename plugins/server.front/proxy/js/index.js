module.exports = function(req, res, next) {
  console.log('Entered proxy mode');
  console.log('params', req.params);
  console.log('body', req.body);
  return console.log('hello');
};
