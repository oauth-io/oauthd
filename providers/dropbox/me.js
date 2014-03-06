var me = {
    fetch: [

        function(fetched_elts) {
            return '/1/account/info';
        }

    ],
    params: {},
    fields: {
        name: 'display_name',
        email: '=',
        location: 'country',
        locale: 'language'
    }
};
module.exports = me;