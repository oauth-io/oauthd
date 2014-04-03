var me = {
    fetch: [

        function() {
            return '/2.2/me?site=stackoverflow';
        }

    ],
    params: {},
    fields: {
        alias: function(me) {
            return me.items && me.items[0] ? me.items[0].display_name : undefined;
        },
        avatar: function(me) {
            return me.items && me.items[0] ? me.items[0].profile_image : undefined;
        }
    }
};

module.exports = me;