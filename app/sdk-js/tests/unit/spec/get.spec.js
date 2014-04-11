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
describe("OAuth result.get method", function() {
    beforeEach(function(done) {
        values = require('../init_tests')();
        values.window.OAuth.initialize('akey');
        values.window.OAuth.redirect('facebook', '');
        done();
    });
    it("should exist", function() {
        var init = initialize_res();
        init.done(function() {
            expect(values.r.get).toBeDefined();
            expect(typeof values.r.get).toBe('function');
        });
    });
    it("should generate right ajax options for non cors", function(done) {
        var init = initialize_res();
        init.done(function() {
            values.jQuery.setAjaxOptionsHandler(function(options) {
                expect(options.url).toBeDefined();
                expect(options.url).toMatch(new RegExp(values.config.oauthd_url + "\/request\/facebook\/" + encodeURIComponent("/me"), "g"));
                expect(options.headers).toBeDefined();
                expect(options.headers.oauthio).toBeDefined();
                expect(options.headers.oauthio).toBeDefined();
                expect(options.headers.oauthio).toMatch(/^k=akey/);
                expect(options.type).toBe("GET");
                return {
                    __success: true
                };
            });
            values.r.get('/me').done(function(r) {
                done();
            }).fail(function(e) {
                done();
            });
        });
    });
    it("should generate right ajax options for cors", function(done) {
        var init = initialize_res({
            data: {
                url: 'https://graph.facebook.com',
                request: {
                    cors: true,
                    url: 'https://graph.facebook.com',
                    "query": {
                        "access_token": "mytoken"
                    }
                }
            }
        });
        init.done(function() {
            values.jQuery.setAjaxOptionsHandler(function(options) {
                expect(options.url).toBeDefined();
                expect(options.url).toMatch(/https:\/\/graph.facebook.com\/me\?access_token=mytoken/);
                expect(options.type).toBe("GET");
                return {
                    __success: true
                };
            });
            values.r.get('/me').done(function(r) {
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
            var result = values.r.get('/me');
            expect(result).toBeDefined();
            
            expect(result.done).toBeDefined();
            expect(typeof result.done).toBe("function");

            expect(result.fail).toBeDefined();
            expect(typeof result.fail).toBe("function");

        });
    });
});