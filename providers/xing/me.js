var me = {
    fetch: [
        function(fetched_elts) {
            return '/v1/users/me';
        }
    ],
    params: {},
    fields: {
        id: function(me) {
            return me.users[0].id;
        },
        name: function(me) {
            return me.users[0].display_name;
        },
        gender: function(me) {
            if (me.users[0].gender == "m")
                return 0
            else
                return 1
        },
        email: function(me) {
            return me.users[0].active_email;
        },
        alias: function(me) {
            return me.users[0].display_name;
        }
    }
};

module.exports = me;