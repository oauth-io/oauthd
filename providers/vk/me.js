var me = {
    fetch: [

        function(fetched_elts) {
            return '/method/users.get?fields=bdate,sex,photo_max_orig,contacts&v=5.74';
        }

    ],
    params: {},
    fields: {
        id: function(me) {
            return me.response && me.response[0] && me.response[0].id || undefined;
        },
        name: function(me) {
            return me.response && me.response[0] ? me.response[0].first_name + ' ' + me.response[0].last_name : undefined;
        },
        firstname: function(me) {
            return me.response && me.response[0] ? me.response[0].first_name : undefined;
        },
        lastname: function(me) {
            return me.response && me.response[0] ? me.response[0].last_name : undefined;
        },
        gender: function(me) {
            if (me.response && me.response[0] && me.response[0].sex) {
                return me.response[0].sex == 2 ? 1: 0;
            }
            return undefined;
        },
        birthdate: function(me) {
            var bdate = me.response && me.response[0] && me.response[0].bdate || undefined;
            if (bdate) {
                var bdayArray = bdate.split(".");
                return {
                    day: bdayArray[0],
                    month: bdayArray[1],
                    year: bdayArray[2]
                }
            }
            return undefined;
        },
        avatar: function(me) {
            return me.response && me.response[0] && me.response[0].photo_max_orig || undefined;
        },
        phone: function(me) {
            return me.response && me.response[0] && me.response[0].mobile_phone || undefined;
        },
        url: function(me) {
            return "https://vk.com/id" + me.response[0].id;
        }
    }
};
module.exports = me;
