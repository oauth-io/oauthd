var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/oauth2/user/whoami';
        }

    ],
    params: {},
    fields: {
        alias: 'username',
        avatar: 'usericonurl'
    }
};
module.exports = me;