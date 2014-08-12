var me = {
    fetch: [

        function(fetched_elts) {
            return '/v2/user/info';
        }

    ],
    params: {},
    fields: {
        alias: function(me) {
            return me.response.user.name;
        }
    }
};
module.exports = me;