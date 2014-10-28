var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/2/account/verify.json';
        }

    ],
    params: {},
    fields: {
        id: function(me) {
            return me.user.id;
        },
        name: function(me) {
            return me.user.name;
        },
        avatar: function(me) {
            return me.user.avatar_url_ssl;
        },
        alias: function(me) {
            return me.user.username;
        }
    }
};
module.exports = me;