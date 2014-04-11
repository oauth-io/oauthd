describe("OAuth popup", function() {

    beforeEach(function() {
        values = require('../init_tests')();
    });


    it("should create a new values.window", function() {
        values.window.OAuth.initialize('akey');
        values.window.OAuth.popup('facebook');
        expect(values.window.popup.url).toBeDefined();
        expect(values.window.popup.name).toBeDefined();
        expect(values.window.popup.options).toBeDefined();
    });

    it("should contain a response when message sent", function() {
        values.window.emitEvent("message");
    });
});