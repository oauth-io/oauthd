var me = {
    fetch: [

        function(fetched_elts) {
            return '/v2/user/info';
        }

    ],
    params: {},
    fields: {
        following: function(me) {
            return me.response.user.following;
        },
        default_post_format: function(me) {
            return me.response.user.default_post_format;
        },
        name: function(me) {
            return me.response.user.name;
        },
        likes: function(me) {
            return me.response.user.likes;
        },
        blogs: function(me) {
            return me.response.user.blogs;
        }
    }
};
module.exports = me;