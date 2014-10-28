var me = {
    fetch: [

        function() {
            return '/3/account/me';
        }

    ],
    params: {},
    fields: {
        alias: function(me) {
            return me.data.url;
        },
        bio: function(me) {
            return me.data.bio;
        }
    }
};

module.exports = me;