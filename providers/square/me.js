var me = {
    url: '/v1/me',
    params: {},
    fields: {
        id: function(me) {
            return "" + me.id;
        },
        name: '=',
        company: 'business_name',
        local: 'language_code',
        email: '=',
        location: '='
    }
};

module.exports = me;
