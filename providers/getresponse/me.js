var me = {
	url: "/accounts",
	params: {},
	fields: {
		accountId: function (me) {
			return me.accountId
		},
		firstName: function (me) {
			return me.firstName
		},
		lastName: function (me) {
			return me.lastName
		},
		email: function (me) {
			return me.email
		},
		href: function (me) {
			return me.href
		}
	}
};
module.exports = me;
