var me = {
    fetch: [

        function(fetched_elts) {
            return '/1/me';
        }

    ],
    params: {},
    fields: {
        id: "=",
        email: "=",
        location: "country",
        name: "=",
        avatar: function(me) {
            return me.image;
        }
    }
};
module.exports = me;
