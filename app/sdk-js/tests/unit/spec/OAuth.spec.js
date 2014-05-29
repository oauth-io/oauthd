describe("OAuth object", function() {

    beforeEach(function() {
        values = require('../init_tests')();
    });

    it("should exist in the window", function() {
        expect(values.window.OAuth).toBeDefined();
    });



});