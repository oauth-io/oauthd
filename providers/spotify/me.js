var me = {
    fetch: [

        function(fetched_elts) {
            return '/v1/me';
        }

    ],
    params: {},
    fields: {
        id: "=",
        location: "country",
        name: function(me) {
            return me.display_name;
        },
        email: function(me) {
            return me.email;
        },
        avatar: function(me) {
            return me.images[0];
        },
        alias: function(me) {
            return me.id;
        }
    }
};
module.exports = me;
