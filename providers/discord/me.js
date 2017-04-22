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
            return me.username + '#' + me.discriminator;
        }
    }
};

module.exports = me;