var me = {

    url: '/user',
    params: {},
    fields: {
        id: function(me) {
            return "" + me.id;
        },
        name: 'name',
        company: '=',
        alias: 'nick',
        bio: '=',
        avatar: 'avatar',
        email: 'email',
        location: '='
    }
};

module.exports = me;
