// this me is not working because http://stocktwits.com/developers/docs/api#account-verify-docs
// it require the access token in params like this:
// https://api.stocktwits.com/api/2/account/verify.json?access_token=<access_token>

var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/2/account/verify.json';
        }

    ],
    params: {},
    fields: {
        id: function(me) {
            return me.user.id;
        },
        name: function(me) {
            return me.user.name;
        },
        avatar: function(me) {
            return me.user.avatar_url_ssl;
        },
        alias: function(me) {
            return me.user.username;
        }
    }
};
module.exports = me;