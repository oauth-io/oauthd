var me = {
    fetch: [

        function() {
            return '/2/member/self';
        }

    ],
    params: {},
    fields: {
        name: '=',
        location: function(me) {
            return me.city + ', ' + me.country;
        },
        locale: 'lang'
    }
};

module.exports = me;