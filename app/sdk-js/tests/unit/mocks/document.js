var appended_elements = [];

module.exports = function(jQuery, window, options) {
    var obj = {
        getAppendedElements: function() {
            return appended_elements;
        },
        body: {
            appendChild: function(elt) {
                appended_elements.push(elt);
            }
        },
        location: {
            hash: options && options.hash ? options.hash : '',
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

                return elt;
            }

        },
        getElementsByTagName: function(tagname) {

            if (tagname == "head") {
                return [{
                    appendChild: function(elt) {

                        appended_elements.push(elt);
                        if (elt.tag == 'script' && elt.src.match(/jquery/)) {
                            window.jQuery = jQuery;
                            elt.onload();
                        }
                    }
                }];
            }
        }
    };
    return obj;
};