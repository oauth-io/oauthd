var me = {
    fetch: [

        function(fetched_elts) {
            return '/me/';
        }

    ],
    params: {},
    fields: {
        alias: 'username',
        name: 'name',
        avatar: function(me) {
            return me.pictures.medium;
        },
        location: function(me) {
            return me.city + ', ' + me.country;
        },
        bio: 'biog'
    }
};
module.exports = me;