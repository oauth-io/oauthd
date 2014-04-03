var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/1.0/users/me';
        }

    ],
    params: {},
    fields: {
        name: function(me) {
            return me.data.name;
        },
        email: function(me) {
            return me.data.email;
        },
        avatar: function(me) {
            return me.data.photo.image_128x128;
        }
    }
};
module.exports = me;