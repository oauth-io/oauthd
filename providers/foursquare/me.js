var me = {
    fetch: [

        function(fetched_elts) {
            var date = new Date();
            return '/v2/users/self?v=' + date.getFullYear() + (date.getMonth() + 1) + date.getDate();
        }
    ],
    params: {},
    fields: {
        name: function(me) {
            return me.response.user.firstName + ' ' + me.response.user.lastName;
        },
        firstname: function(me) {
            return me.response.user.firstName;
        },
        lastname: function(me) {
            return me.response.user.lastName;
        },
        email: function(me) {
            return me.response.user.contact.email;
        },
        gender: function(me) {
            return me.response.user.gender == 'male' ? 0 : 1;
        },
        location: function(me) {
            return me.response.user.homeCity;
        },
        bio: function(me) {
            return me.response.user.bio;
        },
        avatar: function(me) {
            if (me.response.user.photo.suffix) {
                var suffix = me.response.user.photo.suffix;
                suffix.replace(/^\//, '');
                return me.response.user.photo.prefix + suffix;
            } else {
                return me.response.user.photo;
            }
        }
    }
};
module.exports = me;