var me = {
    fetch: [

        function () {
            return '/v3/profile';
        }

    ],
    params: {},
    fields: {
        name: function (me) {
            return me.fullName
        },
        locale: 'lang'
    }
};

module.exports = me;