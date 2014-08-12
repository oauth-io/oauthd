var me = {
    fetch: [

        function(fetched_elts) {
            return '/plus/v1/people/me';
        }

    ],
    params: {},
    fields: {
        name: function(me) {
            return me.displayName;
        },
        firstname: function(me) {
            return me.name ? me.name.givenName : undefined;
        },
        lastname: function(me) {
            return me.name ? me.name.familyName : undefined;
        },
        email: function(me) {
            return me.emails && me.emails[0].value;
        },
        occupation: '=',
        gender: function(me) {
            return me.gender == 'male' ? 0 : 1;
        },
        avatar: function(me) {
            return me.image ? me.image.url : undefined;
        },
        company: function(me) {
            return me.organizations && me.organizations[0] ? me.organizations[0].name : undefined;
        },
        location: function(me) {
            return me.placesLived && me.placesLived[0] ? me.placesLived[0].value : undefined;
        },
        locale: 'language'
    }
};
module.exports = me;