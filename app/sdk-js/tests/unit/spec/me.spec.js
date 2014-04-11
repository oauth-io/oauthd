var Deferred = require('../mocks/defer');
values = {};
var initialize_res = function(opts) {
    var defer = Deferred();
    opts = opts || {};
    opts.data = opts.data || {};
    values = require('../init_tests')({
        hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
            provider: opts.provider || 'facebook',
            state: values.sha1.create_hash(),
            status: opts.success || 'success',
            data: {
                oauth_token: opts.data.oauth_token || 'mytoken',
                oauth_token_secret: opts.data.oauth_token_secret || 'tokensecret',
                request: opts.data.request || {}
            }
        }))
    });
    values.window.OAuth.initialize('akey');
    values.window.OAuth.callback('facebook').done(function(r) {
        values.r = r;
        defer.resolve();
    }).fail(function(e) {
        defer.reject();
    });
    return defer.promise();
};
describe("OAuth result.me method", function() {
    beforeEach(function(done) {
        values = require('../init_tests')();
        values.window.OAuth.initialize('akey');
        values.window.OAuth.redirect('facebook', '');
        done();
    });

    it ("should exist", function () {
        var init = initialize_res();

        init.done(function () {
            expect(values.r).toBeDefined();
        });
    });

    it("should generate right ajax options", function(done) {
        var init = initialize_res();
        init.done(function() {
            values.jQuery.setAjaxOptionsHandler(function(options) {
                expect(options.url).toBeDefined();
                expect(options.url).toMatch("https://oauth.io/auth/facebook/me");

                expect(options.type).toBe("GET");

                expect(options.headers).toBeDefined();
                expect(options.headers.oauthio).toBe("k=akey&oauthv=1&oauth_token=mytoken&oauth_token_secret=tokensecret");
                return {
                    __success: true
                };
            });
            values.r.me(["name"]).done(function(r) {
                expect(r).toBeDefined();
                done();
            }).fail(function(e) {
                done();
            });
        });
    });

    it("should return an object with done and fail methods", function() {
        var init = initialize_res();
        init.done(function() {
            values.jQuery.setAjaxOptionsHandler(function(options) {
                expect(options.url).toBeDefined();
                return {
                    __success: true
                };
            });
            var result = values.r.me(["name"]);
            expect(result).toBeDefined();
            
            expect(result.done).toBeDefined();
            expect(typeof result.done).toBe("function");

            expect(result.fail).toBeDefined();
            expect(typeof result.fail).toBe("function");

        });
    });
});