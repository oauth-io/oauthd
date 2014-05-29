describe("Initialization", function() {
    beforeEach(function() {
        values = require('../init_tests')();
    });
    it("should have appended the jquery script", function() {
        var appended = false;
        var elts = values.document.getAppendedElements();
        for (var k in elts) {
            if (elts[k].tag === "script") {
                if (elts[k].src && elts[k].src === '//code.jquery.com/jquery.min.js') {
                    appended = true;
                }
            }
        }
        expect(appended).toBe(true);
    });
});
beforeEach(function() {
    values = require('../init_tests')();
});