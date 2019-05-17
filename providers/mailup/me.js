var me = {
    url: "/Authentication/Info",
    params: {},
    fields: {
        user_name: function(me) {
            return me ? me.UserName : undefined;
        },
        is_trial: function (me) {
            return me ? me.isTrial : undefined;
        },
        company: function (me) {
            return me ? me.Company : undefined;
        },
        uid: function (me) {
            return me ? me.UID : undefined;
        }
    }
};
module.exports = me;