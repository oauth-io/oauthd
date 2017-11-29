var me = {
    fetch: [

        function(fetched_elts) {
            return '/v1.0/me';
        }

    ],
    params: {},
    fields: {
        name: '=',
        firstname: 'givenName',
        lastname: 'surname',
        email: 'userPrincipalName',
        phones: function(me) {
            return {
                business: me.businessPhones,
                mobile: me.mobilePhone,
            };
        }
    }
};
module.exports = me;