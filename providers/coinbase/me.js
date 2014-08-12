var me = {
    fetch: [

        function(fetched_elts) {
            return '/api/v1/users';
        }

    ],
    params: {},
    fields: {
        id: function (me) {
            return me.users[0].user.id;
        },
        name: function (me) {
            return me.users[0].user.name;
        },
        firstname: function (me) {
            var names = me.users[0].user.name.split(' ');
            return names[0];
        },
        lastname: function (me) {
            var names = me.users[0].user.name.split(' ');
            names.shift();
            return names.join(' ');
        },
        email: function (me) {
            return me.users[0].user.email;
        },
        location: function(me) {
            return me.users[0].user.timezone;
        },
        company: function(me) {
            return me.users[0].user.merchant.company_name;
        },
        balance: function (me) {
            return me.users[0].user.balance;
        },
        buy_limit: function (me) {
            return me.users[0].user.buy_limit;
        },
        sell_limit: function (me) {
            return me.users[0].user.sell_limit;
        },
        buy_level: function (me) {
            return me.users[0].user.buy_level;
        },
        sell_level: function (me) {
            return me.users[0].user.sell_level;
        }
    }
};
module.exports = me;