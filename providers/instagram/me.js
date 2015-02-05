var me = {
    fetch: [
        function(fetched_elts) {
            return '/v1/users/self';
        }
    ],
    params: {},
    fields: {
        id: function(me) {
            return me.data.id || undefined;
        },
        alias: function(me) {
            return me.data.username || undefined;
        },
        name: function(me) {
            return me.data.full_name || undefined;
        },
        avatar: function(me) {
            return me.data.profile_picture || undefined;
        }
    }
};
module.exports = me;
