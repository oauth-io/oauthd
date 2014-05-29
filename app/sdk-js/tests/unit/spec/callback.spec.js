 describe("OAuth.callback", function() {
	beforeEach(function() {
		values = require('../init_tests')();
		values.window.OAuth.initialize('akey');
		values.window.OAuth.redirect('facebook', '');
	});
	it("should be able to return data returned in the server from a hash", function(done) {
		values = require('../init_tests')({
			hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
				provider: 'facebook',
				state: values.sha1.create_hash(),
				status: 'success',
				data: {
					oauth_token: 'mytoken'
				}
			}))
		});
		// values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
		values.window.OAuth.initialize('akey');
		var callback = values.window.OAuth.callback('facebook');
		expect(callback).toBeDefined();
		callback.done(function(r) {
			expect(r).toBeDefined();
			expect(r.oauth_token).toBeDefined();
			expect(r.oauth_token).toBe('mytoken');
			done();
		}).fail(function(e) {
			expect(e).not.toBeDefined();
			done();
		});
	});
	it("should be able to store result to cache", function(done) {
		values = require('../init_tests')({
			hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
				provider: 'facebook',
				state: values.sha1.create_hash(),
				status: 'success',
				data: {
					oauth_token: 'mytoken'
				}
			}))
		});
		values.window.OAuth.initialize('akey');
		var callback = values.window.OAuth.callback('facebook', {
			cache: true
		});
		expect(callback).toBeDefined();
		callback.done(function(r) {
			expect(r).toBeDefined();
			expect(r.oauth_token).toBeDefined();
			expect(r.oauth_token).toBe('mytoken');
			expect(JSON.parse(decodeURIComponent(values.cookies.readCookie("oauthio_provider_facebook"))).oauth_token).toBe('mytoken');
			done();
		}).fail(function(e) {
			expect(e).not.toBeDefined();
			done();
		});
	});
	it("should be able to retrieve result to cache", function(done) {
		var callback = values.window.OAuth.callback('facebook', {
			cache: true
		});
		callback.done(function(r) {
			expect(JSON.parse(decodeURIComponent(values.cookies.readCookie("oauthio_provider_facebook"))).oauth_token).toBe('mytoken');
			done();
		}).fail(function(e) {
			expect(e).not.toBeDefined();
			done();
		});
	 });
	// it("should create an error when the state is wrong", function(done) {
	//     values = require('../init_tests')({
	//         hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
	//             provider: 'facebook',
	//             state: 'wrongstate',
	//             status: 'success',
	//             data: {
	//                 oauth_token: 'mytoken'
	//             }
	//         }))
	//     });
	//     values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
	//     values.window.OAuth.initialize('akey');
	//     values.window.OAuth.callback('facebook').done(function(r) {
	//         expect(r).toBeDefined();
	//         expect(r.oauth_token).toBeDefined();
	//         expect(r.oauth_token).toBe('mytoken');
	//         done();
	//     });
	// });
 });