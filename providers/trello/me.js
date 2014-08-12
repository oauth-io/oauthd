var me = {
    fetch: [

        function(fetched_elts) {
            return '/1/members/me';
        }

    ],
    params: {},
    fields: {
        alias: 'username',
        bio: '=',
        name: 'fullName',
        email: '='
    }
};
module.exports = me;