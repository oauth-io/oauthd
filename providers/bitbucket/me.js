var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/1.0/user';
        }

    ],
    params: {},
    fields: {
        alias: function(me) {
            return me.user.display_name || me.user.username;
        },
        name: function(me) {
            return me.user.firstname || me.user.lastname ? me.user.firstname + ' ' + me.user.lastname : undefined;
        },
        avatar: function(me) {
            return me.user.avatar;
        }
    }
};
module.exports = me;