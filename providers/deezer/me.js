var me = {
    fetch: [

        function(fetched_elts) {
            return '/user/me';
        }

    ],
    params: {},
    fields: {
        alias: 'name',
        name: function(me) {
            return me.firstname + ' ' + me.lastname;
        },
        firstname: '=',
        lastname: '=',
        email: '=',
        birthdate: function(me) {
            var array = me.birthday.split('-');
            return {
                day: array[2],
                month: array[1],
                year: array[0]
            }
        },
        location: 'country',
        language: 'lang',
        gender: function(me) {
            return me.gender == 'M' ? 0 : 1;
        },
        avatar: 'picture'
    }
};
module.exports = me;