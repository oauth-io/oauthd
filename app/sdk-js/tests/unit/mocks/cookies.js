var data = {};

module.exports = function() {
    return {
        init: function() {

        },
        createCookie: function(name, value, expires) {
            data[name] = {
                value: value,
                expires: expires
            };

        },
        readCookie: function(name) {
            return data[name];
        },
        eraseCookie: function(name) {
            data[name] = undefined;
        }
    };
};