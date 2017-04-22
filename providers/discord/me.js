var me = {
    fetch: [
        function() {
            return 'https://discordapp.com/api/users/@me';
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
            return me.email;
        },
        discriminator: function(me) {
            return me.discriminator;
        },
        fullName: function(me) {
            if (me.username && me.discriminator) {
                return me.username + '#' + me.discriminator;
            }

            return undefined;
        }
    }
};

module.exports = me;