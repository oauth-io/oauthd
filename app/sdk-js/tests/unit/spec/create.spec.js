 describe("OAuth.create", function() {
	beforeEach(function() {
		values = require('../init_tests')();
		values.window.OAuth.initialize('akey');
		values.window.OAuth.redirect('facebook', '');
	});

	it ("should exist", function () {
		expect(values.window.OAuth.create).toBeDefined();
	});

	it("should be able to create a OAuth result object from cache", function () {
		values.cookies.createCookie('oauthio_provider_facebook', encodeURIComponent(JSON.stringify({
			oauth_token: 'mytoken',
			oauth_token_secret: 'mytokensecret'
		})));

		var response = values.window.OAuth.create('facebook');
		expect(response).toBeDefined();

		expect(response.get).toBeDefined();
		expect(typeof response.get).toBe('function');

		expect(response.post).toBeDefined();
		expect(typeof response.post).toBe('function');

		expect(response.put).toBeDefined();
		expect(typeof response.put).toBe('function');

		expect(response.del).toBeDefined();
		expect(typeof response.del).toBe('function');

		expect(response.patch).toBeDefined();
		expect(typeof response.patch).toBe('function');

		expect(response.me).toBeDefined();
		expect(typeof response.me).toBe('function');
	});

	it("should be able to create a OAuth result object from parameters", function () {

		var response = values.window.OAuth.create('facebook', {
			oauth_token: 'mytoken',
			oauth_token_secret: 'mytokensecret'
		}, {
			cors: true,
            url: 'https://graph.facebook.com',
            "query": {
                "access_token": "mytoken"
            }
		});
		expect(response).toBeDefined();

		expect(response.get).toBeDefined();
		expect(typeof response.get).toBe('function');

		expect(response.post).toBeDefined();
		expect(typeof response.post).toBe('function');

		expect(response.put).toBeDefined();
		expect(typeof response.put).toBe('function');

		expect(response.del).toBeDefined();
		expect(typeof response.del).toBe('function');

		expect(response.patch).toBeDefined();
		expect(typeof response.patch).toBe('function');

		expect(response.me).toBeDefined();
		expect(typeof response.me).toBe('function');
	});


});