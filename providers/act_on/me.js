var me = {
    url: '/api/1/account',
    params: {},
    fields: {
        id: function (me) {
            return me.account_id;
        },
        user_name: function (me) {
            return me.user_name;
        },
        user_email: function (me) {
            return me.user_email;
        },
        cname: function (me) {
            return me.cname;
        },
        user_type: function (me) {
            return me.user_type;
        },
        account_name: function (me) {
            return me.account_name;
        },
        is_admin: function (me) {
            return me.isAdmin;
        }
    }
};
module.exports = me;
