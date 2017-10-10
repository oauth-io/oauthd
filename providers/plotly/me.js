var me = {
    fetch: [
      function() {
          return 'https://api-local.plot.ly/v2/users/current/';
      }
    ],
    params: {},
    fields: {
        id: function(me) {
          return me.id;
        },
        name: function(me) {
          return me.username;
        },
        email: function(me) {
          return me.email;
        },
        nickname: function(me) {
              return me.nickname;
        }
    }
};

module.exports = me;
