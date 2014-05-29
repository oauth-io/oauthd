var me = {
    fetch: [

        function(fetched_elts) {
            return '/method/users.get';
        }

    ],
    params: {},
    fields: {
        name: function(me) {
            return me.response && me.response[0] ? me.response[0].first_name + ' ' + me.response[0].last_name : undefined;
        },
        firstname: function(me) {
            return me.response && me.response[0] ? me.response[0].first_name : undefined;
        },
        lastname: function(me) {
            return me.response && me.response[0] ? me.response[0].last_name : undefined;
        }
    }
};
module.exports = me;