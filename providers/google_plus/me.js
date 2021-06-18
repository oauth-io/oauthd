var me = {
    fetch: [
        function(fetched_elts) {
            return '/oauth2/v3/userinfo';
        }
    ],

    params: {},

    fields: {
        id: '=',
        name: function(me) {
            if (me && me.raw && me.raw.name) { return me.raw.name; }
            return me.displayName;
        },

        firstname: function(me) {
            if (me.given_name) { return me.given_name; }
            return me.name ? me.name.givenName : undefined;
        },

        lastname: function(me) {
            if (me.family_name) { return me.family_name; }
            return me.name ? me.name.familyName : undefined;
        },

        email: function(me) {
            if (me && me.raw && me.raw.email) { return me.raw.email; }
            if (me.email) { return me.email; }
            return me.emails && me.emails[0].value;
        },

        occupation: '=',

        gender: function(me) {
            if (me.gender == 'male')
                return 0;
            if (me.gender == 'female')
                return 1;
            return undefined;
        },

        avatar: function(me) {
            if (me.picture) { return me.picture; }
            return me.image ? me.image.url : undefined;
        },

        company: function(me) {
            return me.organizations && me.organizations[0] ? me.organizations[0].name : undefined;
        },

        location: function(me) {
            return me.placesLived && me.placesLived[0] ? me.placesLived[0].value : undefined;
        },

        locale: 'language',

        url: '='
    }
};
module.exports = me;
