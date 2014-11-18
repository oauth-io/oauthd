var me = {
    fetch: [

        function(fetched_elts) {
            return '/v7.0/user/self/';
        }

    ],
    params: {},
    fields: {
        id: '=',
        name: "display_name",
        alias: "username",
        firstname: "first_name",
        lastname: "last_name",
        email: "=",
        gender: function(me) {
            return me.gender == 'M' ? 0 : 1;
        },
        location: function(me) {
            return me.location.locality + ', ' + me.location.country;
        }
    }
};
module.exports = me;