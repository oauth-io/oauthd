describe("OAuth initialization", function() {
    beforeEach(function() {
        values = require('../init_tests')();
    });

    it("should be able to give the current version of the SDK", function() {
        expect(values.window.OAuth.getVersion).toBeDefined();
        expect(typeof values.window.OAuth.getVersion()).toBe('string');
        expect(values.window.OAuth.getVersion()).toBe(values.config.version);
    });

    it("should be able to set the oauthd URL", function() {
        values.window.OAuth.setOAuthdURL('https://myurl.com');
        expect(values.config.oauthd_url).toBe('https://myurl.com');
        expect(values.config.oauthd_base).toBe('https://myurl.com');

    });

    it("should be able to init with an app key", function() {
        values.window.OAuth.initialize('akey');
        expect(values.config.key).toBeDefined();
        expect(values.config.key).toBe('akey');
    });

    it("should be able to init with an app key and options", function() {
        values.window.OAuth.initialize('akey', {
            myoption: 'option_text'
        });
        expect(values.config.key).toBeDefined();
        expect(values.config.key).toBe('akey');
        expect(values.config.options).toBeDefined();
        expect(values.config.options.myoption).toBe('option_text');
    });
});