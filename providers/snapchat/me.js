var me = {
    fetch: [

        function(fetched_elts) {
            return 'https://kit.snapchat.com/v1/me?query={me{displayName, externalId, bitmoji{avatar}}}';
        }

    ],
    params: {},
    fields: {
        bitmoji: function(me) {
            return me.bitmoji;
        },
        name: function(me) {
            return me.display_name;
        },
        id: function(me) {
            return me.externalId;
        }
    }
};
module.exports = me;
