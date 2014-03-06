var me = {
    fetch: [{
            url: '/1/user',
            export: {
                profile_id: function(result) {
                    return result.profiles[0].id;
                }
            }
        },
        function(fetched_elts) {
            return '/1/names/' + fetched_elts.profile_id + '/';
        }

    ],
    params: {},
    fields: {
        name: function(me) {
            return me.first_name + ' ' + me.last_name;
        },
        firstname: function(me) {
            return me.first_name;
        },
        lastname: function(me) {
            return me.last_name;
        }
    }
};
module.exports = me;