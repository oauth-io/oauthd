/* global module */

module.exports = {
    fetch: [
        function(fetched_elts) {
            return "/oauth2/v3/userinfo";
        },
    ],

    params: {},

    fields: {
        company: function(me) { return me.organizations && me.organizations[0] ? me.organizations[0].name : undefined; },
        email: function(me) { return me.emailAddresses && me.emailAddresses[0] ? me.emailAddresses[0].value : undefined; },
        firstname: function(me) { return me.names ? me.names.givenName : undefined; },
        id: '=',
        lastname: function(me) { return me.names ? me.names.familyName : undefined; },
        locale: function(me) { return me.locales && me.locales[0] ? me.locales[0].value : undefined; },
        location: function(me) { return me.addresses && me.addresses[0] ? me.addresses[0].value : undefined; },
        name: function(me) { return me.names ? me.names.displayName : undefined; },
        occupation: '=',
    }
};
