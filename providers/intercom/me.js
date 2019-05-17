var me = {
    url: "https://api.intercom.io/me",
    params: {},
    fields: {
        id: function(me) {
            return me.id;
        },
        email: function(me) {
            return me.email;
        },
        type: function(me) {
            return me.type;
        },
        name: function(me) {
            return me.name;
        },
        app: function(me) {
            return me.app;
        },
        avatar: function(me) {
            return me.avatar;
        }
    }
}

module.exports = me;
