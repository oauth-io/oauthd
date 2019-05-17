var me = {
    url: "https://login.mailchimp.com/oauth2/metadata",
    params: {},
    fields: {
        account_name: function(me) {
            return me.accountname;
        },
        role: function(me) {
            return me.role;
        },
        dc: function(me) {
            return me.dc;
        },
        api_endpoint: function(me) {
            return me.api_endpoint;
        }
    }
};
module.exports = me;