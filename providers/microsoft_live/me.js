var me = {
    fetch: [

        function(fetched_elts) {
            return '/v1.0/me';
        }

    ],
    params: {},
    fields: {
        name: 'displayName',
        firstname: 'givenName',
        lastname: 'surname',
        email: 'mail',
        phones: function(me) {
            return {
                mobile: me.mobilePhone
            };
        }
    }
};
module.exports = me;
