describe("OAuth.clearCache", function () {
	beforeEach(function () {
		values = require('../init_tests')();

	});

	it("should remove a given provider from the cache", function () {
		values.cookies.createCookie('oauthio_provider_myprovider', 'somevalue', 'somedate');

		expect(values.cookies.readCookie('oauthio_provider_myprovider')).toBeDefined();
		
		values.window.OAuth.clearCache('myprovider');
		expect(values.cookies.readCookie('oauthio_provider_myprovider')).not.toBeDefined();

	});
});