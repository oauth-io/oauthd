var db = require('../lib/db');

db.redis.del('adm:salt', 'adm:pass', 'adm:name', function(e, r) {
	next = function() { process.kill(process.pid, 'SIGUSR2'); }

	if (e) return next(console.error('\x1B[35m', e, '\x1B[39m'));
	if (r < 3) return next(console.error('\x1B[35mNothing to reset (already empty)\x1B[39m'));
	console.log('\x1B[32mCredentials reset !\x1B[39m');
	next();
});