var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/3.0/users/details.json';
        }

    ],
    params: {},
    fields: {
        alias: function(me) {
            return me.response.username;
        },
        name: function(me) {
            return me.response.name;
        },
        bio: function(me) {
            return me.response.about;
        },
        location: function(me) {
            return me.response.location;
        },
        avatar: function(me) {
            if (me.response && me.response.avatar && me.response.avatar.large)
                return me.response.avatar.large.permalink;
            else
                return undefined;
        }
    }
};
module.exports = me;