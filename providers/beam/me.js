var me = {
    fetch: [
        function (fetched_elts) {
            return "/users/current";
        }
    ],
    params: {},
    fields: {
        id: function(me) {
            return me.id;
        },
        name: function(me) {
            return me.username;
        },
        email: function(me) {
            return me.email || null;
        },
        avatar: function(me) {
            return me.avatarUrl;
        },
        bio: function(me) {
            return me.bio;
        }
    }
};