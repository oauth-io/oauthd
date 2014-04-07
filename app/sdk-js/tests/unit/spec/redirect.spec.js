describe("OAuth redirect", function() {
    beforeEach(function() {
        values = require('../init_tests')();
    });

    it("should change the location", function() {
        values.window.OAuth.initialize('akey');
        values.window.OAuth.redirect('facebook', '');
        expect(values.document.location.href).toMatch(/https:\/\/oauth.io\/auth\/facebook\?k=akey/);
    });

    it("should use the cache if specified", function() {
        values.window.OAuth.initialize('akey', {
            cache: true
        });
        values.window.OAuth.redirect('facebook', '');

    });


});