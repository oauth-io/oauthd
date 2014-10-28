var me = {
    fetch: [

        function(fetched_elts) {
            console.log(fetched_elts.provider_config.oauth1);
            return '/user?action=getbyuserid&userid=' + fetched_elts.userid;
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