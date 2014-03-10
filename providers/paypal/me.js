var me = {
    fetch: [

        function() {
            return '/v1/identity/openidconnect/userinfo/?schema=openid';
        }

    ],
    params: {},
    fields: {
        name: '=',
        firstname: 'given_name',
        lastname: 'family_name',
        email: '=',
        avatar: 'picture',
        birthdate: function(me) {
            var dates = me.birthdate.split('-');
            return {
                day: dates[2] ? dates[2] : undefined,
                month: dates[1] ? dates[1] : undefined,
                year: dates[0] ? dates[0] : undefined
            };
        },
        phone: 'phone_number',
        address: '='
    }
};

module.exports = me;