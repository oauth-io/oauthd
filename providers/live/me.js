var me = {
    fetch: [

        function(fetched_elts) {
            return '/v5.0/me';
        }

    ],
    params: {},
    fields: {
        name: '=',
        firstname: 'first_name',
        lastname: 'last_name',
        birthdate: function(me) {
            return {
                day: me.birth_date,
                month: me.borth_month,
                year: me.birth_year
            };
        },
        email: function(me) {
            return emails.preferred;
        },
        address: function(me) {
            return {
                personal: me.addresses.personal,
                business: me.addresses.business,
                generic: me.addresses.personal
            };
        },
        phones: function(me) {
            return {
                personal: me.phones.personal,
                business: me.phones.business,
                mobile: me.phones.mobile,
                generic: me.phones.mobile
            };
        }
    }
};
module.exports = me;