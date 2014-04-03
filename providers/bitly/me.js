var me = {
    fetch: [

        function(fetched_elts) {
            return '/v3/user/info';
        }

    ],
    params: {},
    fields: {
        alias: function(me) {
            return me.data.login;
        },
        name: function(me) {
            return me.data.display_name || me.data.full_name;
        },
        avatar: function(me) {
            return me.data.profile_image;
        }
    }
};
module.exports = me;