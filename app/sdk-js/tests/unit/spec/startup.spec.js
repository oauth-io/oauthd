var initialize = require('../init_tests');
var values = {};

describe("Initialization", function() {
    beforeEach(function() {
        values = initialize();
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