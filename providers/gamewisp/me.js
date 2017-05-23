var me = {
    fetch: [
        function() {
            return 'https://api.gamewisp.com/pub/v1/channel/information';
        }
    ],
    params: {},
    fields: {
        id: function(me) {
            return me.data.id;
        },
        name: function(me) {
            return me.data.name;
        },
        displayName: function(me) {
            return me.data.display_name;
        },
        description: function(me) {
            return me.data.description;
        },
        url: function(me) {
            return "https://gamewisp.com" + me.data.links.uri;
        }
    }
};

module.exports = me;