var me = {
    fetch: [

        function(fetched_elts) {
            return '/v2.5/me?fields=name,first_name,last_name,email,gender,location,locale,work,languages,birthday,relationship_status,hometown,picture';
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
            if (me.gender == 'male')
                return 0;
            if (me.gender == 'female')
                return 1;
            return undefined;
        },
        location: function(me) {
            return me.location ? me.location.name : undefined;
        },
        locale: '=',
        company: function(me) {
            return me.work && me.work[0] && me.work[0].employer ? me.work[0].employer.name : undefined;
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
                if (array.length == 3) {
                    return {
                        day: array[1],
                        month: array[0],
                        year: array[2]
                    }
                } else if (array.length == 2) {
                    return {
                        day: array[1],
                        month: array[0]
                    }
                } else if (array.length == 1) {
                    return {
                        year: array[0]
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