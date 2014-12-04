var me = {
    fetch: [

        function(fetched_elts) {
            return '/users/me';
        }

    ],
    params: {},
    fields: {
        id: function(me) {
            return me.data.id;
        },
        location: function(me) {
            return me.data.locale;
        },
        name: function(me) {
            return me.data.username;
        },
        avatar: function(me) {
            return me.data.avatar_image.url;
        },
        alias: function(me) {
            return me.data.username;
        }
    }
};
module.exports = me;
