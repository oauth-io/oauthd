var me = {
    fetch: [

        function(fetched_elts) {
            return '/v3/athlete';
        }

    ],
    params: {},
    fields: {
        id: "=",
        name: function (me) {
            return me.firstname + ' ' + me.lastname;
        },
        firstname: "=",
        lastname: "=",
        gender: function (me) {
            return me.sex == 'M' ? 0 : 1;
        },
        avatar: "profile_medium",
        email: "=",
        location: function(me) {
            return me.city + ', ' + me.state + ', ' + me.country;
        }
    }
};
module.exports = me;