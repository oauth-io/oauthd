var me = {
    fetch: [

        function(fetched_elts) {
            return '/v1/users';
        }

    ],
    params: {},
    fields: {
        name: function(me) {
            return me.user.firstname || me.user.lastname ? me.user.firstname + ' ' +
                me.user.lastname : me.user.fullname;
        },
        firstname: function(me) {
            return me.user.firstname;
        },
        lastname: function(me) {
            return me.user.lastname;
        },
        email: function(me) {
            return me.user.email;
        },
        avatar: function(me) {
            return me.user.avatars.
            default.http;
        },
        location: function(me) {
            return me.user.city + ', ' + me.user.country
        }
    }
};
module.exports = me;