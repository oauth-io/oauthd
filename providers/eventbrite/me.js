var me = {
    fetch: [

        function(fetched_elts) {
            return '/v3/users/me/';
        }

    ],
    params: {},
    fields: {
        email: function(me) {
            return me.emails.email;
        },
        name: '=',
        firstname: 'first_name',
        lastname: 'last_name'
    }
};
module.exports = me;