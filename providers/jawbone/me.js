var me = {
    fetch: [

        function(fetched_elts) {
            return '/v.1.1/users/@me';
        }

    ],
    params: {},
    fields: {
        id: function (me) {
            return me.data.xid;
        },
        name: function(me) {
            return me.data.first + ' ' + me.data.last;
        },
        firstname: function(me) {
            return me.data.first;
        },
        lastname: function(me) {
            return me.data.last;
        },
        gender: function(me) {
            return me.data.gender ? 1 : 0;
        },
        avatar: function(me) {
            return me.data.image;
        },
        height: function (me) {
            return me.data.height;
        },
        weight: function (me) {
            return me.data.weight;
        }
    }
};
module.exports = me;