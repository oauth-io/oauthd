var me = {
    fetch: [

        function(fetched_elts) {
            return '/me.json';
        }

    ],
    params: {},
    fields: {
        name: 'full_name',
        firstname: 'first_name',
        lastname: 'last_name',
        alias: 'username',
        avatar: 'avatar_url',
        location: function(me) {
            return me.city && me.country ? me.city + ' ' + me.country : undefined;
        }
    }
};
module.exports = me;