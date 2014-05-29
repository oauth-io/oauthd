describe("OAuth object", function() {

    beforeEach(function() {
        values = require('../init_tests')();
    });

    it("should exist", function() {
        expect(values.window.OAuth).toBeDefined();
    });

    it("should contain an initialize method", function() {
        expect(values.window.OAuth.initialize).toBeDefined();
    });

    it("should contain a create method", function() {
        expect(values.window.OAuth.create).toBeDefined();
    });

    it("should contain a redirect method", function() {
        expect(values.window.OAuth.redirect).toBeDefined();
    });

    it("should contain a callback method", function() {
        expect(values.window.OAuth.callback).toBeDefined();
    });

    it("should contain a popup method", function() {
        expect(values.window.OAuth.popup).toBeDefined();
    });




});