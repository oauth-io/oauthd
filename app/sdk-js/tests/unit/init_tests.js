module.exports = function(options) {

    var jQuery = require('./mocks/jquery')(options);

    var config = require('./mocks/config')(options);
    var window = require('./mocks/window')(config, options);
    var document = require('./mocks/document')(jQuery, window, options);
    window.setDocument(document, options);
    var cookies = require('./mocks/cookies')(options);
    var sha1 = require('./mocks/sha1')();
    var popup = {

    }
    var navigator = {
        userAgent: 'chrome',
        appVersion: '22.0'
    };

    var rewire = require('rewire');
    var oauth_creator = rewire('./../../js/lib/oauth');
    oauth_creator.__set__('config', config);
    oauth_creator.__set__('cookies', cookies);
    oauth_creator.__set__('sha1', sha1);
    oauth_creator = oauth_creator(window, document, jQuery, navigator);
    oauth_creator(window);
    var values = {
        document: document,
        jQuery: jQuery,
        config: config,
        cookies: cookies,
        navigator: navigator,
        window: window,
        sha1: sha1
    };
    return values;
};