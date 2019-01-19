var me = {
    fetch: [

        function(fetched_elts) {
            return 'https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,occupations,organizations,addresses,locales';
        }

    ],
    params: {},
    fields: {
        id: '=',
        name: function(me) {
            return me.names ? me.names.displayName : undefined;
        },
        firstname: function(me) {
            return me.names ? me.names.givenName : undefined;
        },
        lastname: function(me) {
            return me.names ? me.names.familyName : undefined;
        },
        email: function(me) {
            return me.emailAddresses && me.emailAddresses[0] ? me.emailAddresses[0].value : undefined;
        },
        occupation: '=',
        company: function(me) {
            return me.organizations && me.organizations[0] ? me.organizations[0].name : undefined;
        },
        location: function(me) {
            return me.addresses && me.addresses[0] ? me.addresses[0].value : undefined;
        },
        locale: function(me) {
            return me.locales && me.locales[0] ? me.locales[0].value : undefined;
        }
    }
};
module.exports = me
