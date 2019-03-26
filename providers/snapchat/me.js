var me = {
    fetch: [

        function(fetched_elts) {
            return 'https://kit.snapchat.com/v1/me?query=%7Bme%7BdisplayName%2C%20externalId%2C%20bitmoji%7Bavatar%7D%7D%7D';
        }

    ],
    params: {},
    fields: {
        bitmoji: function(me) {
            return me.bitmoji;
        },
        name: function(me) {
            return me.display_name;
        },
        id: function(me) {
            return me.externalId;
        }
    }
};
module.exports = me;
