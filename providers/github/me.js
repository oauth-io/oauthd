var me = {

    url: '/user',
    params: {},
    fields: {
        id: function(me) {
            return "" + me.id;
        },
        name: '=',
        company: '=',
        alias: 'login',
        bio: '=',
        avatar: 'avatar_url',
        email: '=',
        location: '='
    }
};

module.exports = me;