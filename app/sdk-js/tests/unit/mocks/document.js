var sinon = require('sinon');

var appended_elements = [];

module.exports = function() {
    return {
        getAppendedElements: function() {
            return appended_elements;
        },
        body: {
            appendChild: function(elt) {
                appended_elements.push(elt);
            }
        },
        location: {
            hash: '',
            href: '',
            reload: function() {

            },
            protocol: 'http:',
            host: 'mytest',
            pathname: '/'
        },
        createElement: function(tagname) {
            if (tagname === "script") {
                var elt = {
                    tag: tagname,
                    onload: function() {

                    }
                };

                setTimeout(function() {
                    elt.onload({});
                }, 500);

                return elt;
            }

        },
        getElementsByTagName: function(tagname) {
            if (tagname == "head") {
                return [{
                    appendChild: function(elt) {
                        appended_elements.push(elt);
                    }
                }];
            }
        }
    };
};