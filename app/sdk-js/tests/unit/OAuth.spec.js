var document = require('./mocks/document')();
var jQuery = require('./mocks/jquery')();
var window = require('./mocks/window')(document);
var config = require('./mocks/config')();
var cookies = require('./mocks/cookies')();
var popup = {

}
var navigator = {
    userAgent: 'chrome',
    appVersion: '22.0'
};

var rewire = require('rewire');
var oauth_creator = rewire('../../js/lib/oauth');
oauth_creator.__set__('config', config);
oauth_creator.__set__('cookies', cookies);
oauth_creator = oauth_creator(window, document, jQuery, navigator);
oauth_creator(window);

describe("OAuth object", function() {
    it("should exist", function() {
        expect(window.OAuth).toBeDefined();
    });

    it("should be able to give the current version of the SDK", function() {
        expect(window.OAuth.getVersion).toBeDefined();
        expect(typeof window.OAuth.getVersion()).toBe('string')
    });

    it("should contain an initialize method", function() {
        expect(window.OAuth.initialize).toBeDefined();
    });

    it("should contain a create method", function() {
        expect(window.OAuth.create).toBeDefined();
    });

    it("should contain a redirect method", function() {
        expect(window.OAuth.redirect).toBeDefined();
    });

    it("should contain a callback method", function() {
        expect(window.OAuth.callback).toBeDefined();
    });

    it("should contain a popup method", function() {
        expect(window.OAuth.popup).toBeDefined();
    });
});

describe("OAuth redirect", function() {
    it("should change the location", function() {
        window.OAuth.initialize('akey');
        window.OAuth.redirect('facebook', '');
        expect(document.location.href).toMatch(/https:\/\/oauth.io\/auth\/facebook\?k=akey/);
    });
});

describe("OAuth popup", function() {


    it("should create a new window", function() {
        window.OAuth.initialize('akey');
        window.OAuth.popup('facebook');
        expect(window.popup.url).toBeDefined();
        expect(window.popup.name).toBeDefined();
        expect(window.popup.options).toBeDefined();
    });

    it("should contain a response when message sent")
});