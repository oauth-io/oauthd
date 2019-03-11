var me = {
    fetch: [

        function(fetched_elts) {
            return 'https://adsapi.snapchat.com/v1/me';
        }

    ],
    params: {},
    fields: {
        email: function(me) {
            return me.email;
        },
        name: function(me) {
            return me.display_name;
        }
    }
};
module.exports = me;