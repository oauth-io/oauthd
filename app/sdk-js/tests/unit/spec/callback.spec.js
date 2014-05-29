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

	it("should be able to return data returned in the server from a hash (with template)", function(done) {
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
		var callback = values.window.OAuth.callback('facebook', function (e, r) {
			expect(e).toBe(null);
			expect(r).toBeDefined();
			expect(r.oauth_token).toBeDefined();
			expect(r.oauth_token).toBe('mytoken');
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
	it("should throw an error when the state is not matching", function(done) {
	    values = require('../init_tests')({
	        hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
	            provider: 'facebook',
	            state: 'wrongstate',
	            status: 'success',
	            data: {
	                oauth_token: 'mytoken'
	            }
	        }))
	    });
	    var base = this;
	    values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
	    values.window.OAuth.initialize('akey');
	    values.window.OAuth.callback('facebook')
	    .done(function (r) {
    		base.fail();	
	    	done();
	    })
	    .fail(function(e) {
	    	expect(e).toBeDefined();
	    	expect(e.message).toBe('State is not matching');
	        done();
	    });
	});

	it("should throw an error when the state is not matching (with callback)", function(done) {
	    values = require('../init_tests')({
	        hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
	            provider: 'facebook',
	            state: 'wrongstate',
	            status: 'success',
	            data: {
	                oauth_token: 'mytoken'
	            }
	        }))
	    });
	    var base = this;
	    values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
	    values.window.OAuth.initialize('akey');
	    values.window.OAuth.callback('facebook', function (e, r) {
			expect(e).toBeDefined();
    		expect(e.message).toBe('State is not matching');
    		expect(r).not.toBeDefined();
	        done();
	    });
	});

	it("should throw an error when the provider throws one", function(done) {
	    values = require('../init_tests')({
	        hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
	            provider: 'facebook',
	            state: values.sha1.create_hash(),
	            status: 'error',
	            data: {
	                oauth_token: 'mytoken'
	            }
	        }))
	    });
	    var base = this;
	    values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
	    values.window.OAuth.initialize('akey');
	    values.window.OAuth.callback('facebook')
	    .done(function (r) {
    		base.fail();	
	    	done();
	    })
	    .fail(function(e) {
	    	expect(e).toBeDefined();
	    	done();
	    });
	});

	it("should throw an error when the provider throws one with callback", function(done) {
	    values = require('../init_tests')({
	        hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
	            provider: 'facebook',
	            state: values.sha1.create_hash(),
	            status: 'error',
	            data: {
	                oauth_token: 'mytoken'
	            }
	        }))
	    });
	    var base = this;
	    values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
	    values.window.OAuth.initialize('akey');
	    values.window.OAuth.callback('facebook', function (e, r) {
	    	expect(e).toBeDefined();
	    	expect(r).not.toBeDefined();
	    	done();
	    });
	});

	it("should throw an error when returned provider is wrong", function(done) {
	    values = require('../init_tests')({
	        hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
	            provider: 'fcBoop',
	            state: values.sha1.create_hash(),
	            status: 'success',
	            data: {
	                oauth_token: 'mytoken'
	            }
	        }))
	    });
	    var base = this;
	    values.cookies.createCookie('oauthio_state', values.sha1.create_hash());
	    values.window.OAuth.initialize('akey');
	    values.window.OAuth.callback('facebook')
	    .done(function (r) {
    		base.fail();	
	    	done();
	    })
	    .fail(function(e) {
	    	expect(e).toBeDefined();
	    	done();
	    });
	});
 });