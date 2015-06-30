var me = {
    fetch: [

        function(fetched_elts) {
            return '/v2.3/me';
        }

    ],
    params: {},
    fields: {
        id: '=',
        avatar: function (me) {
            return 'https://graph.facebook.com/v2.3/' + me.id + '/picture';
        },
        name: '=',
        firstname: 'first_name',
        lastname: 'last_name',
        email: '=',
        gender: function(me) {
            return me.gender == 'male' ? 0 : 1;
        },
        location: function(me) {
            return me.location ? me.location.name : undefined;
        },
        local: '=',
        company: function(me) {
            return me.work && me.work[0] ? me.work[0].employer.name : undefined;
        },
        occupation: function(me) {
            return me.work && me.work[0] ? me.work[0].position : undefined;
        },
        language: function(me) {
            return me.languages && me.languages[0] ? me.languages[0].name : undefined;
        },
        alias: 'username',
        birthdate: function(me) {
            if (me.birthday) {
                var array = me.birthday.split('/');
                if (array) {
                    return {
                        day: array[0],
                        month: array[1],
                        year: array[2]
                    }
                }
            }
            return undefined;

        },
        url: function(me) {
            // app scoped id, username is deprecated (https://developers.facebook.com/docs/apps/upgrading#upgrading_v2_0_graph_api)
            return 'https://www.facebook.com/' + me.id;
        }
    }
};
module.exports = me;