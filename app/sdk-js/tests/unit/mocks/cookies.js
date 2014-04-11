var data = {
    oauthio_state: {
        value: 'somestate',
        expires: new Date()
    }
};

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
            if (data[name])
                return data[name].value;
            else
                return undefined;
        },
        eraseCookie: function(name) {
            data[name] = undefined;
        },
        getCacheLength: function () {
            var i = 0;
            for (var k in data) {
                i++;
            }
            return i;
        }
    };
};