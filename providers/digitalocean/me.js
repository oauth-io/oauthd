var me = {

    url: '/v2/account',
    params: {},
    fields: {
        id: function(me) {
            return "" + me.account.uuid;
        },
        email: function(me) {
            return "" + me.account.email;
        }
    }
};

module.exports = me;