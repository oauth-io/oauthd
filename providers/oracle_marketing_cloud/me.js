var me = {
	url: "https://login.eloqua.com/id",
	params: {},
	fields: {
		name: function (me) {
			return me.user ? me.user.displayName : undefined;
		},
		firstname: function (me) {
			return me.user ? me.user.firstName : undefined;
		},
		lastname: function (me) {
			return me.user ? me.user.lasttName : undefined;
		},
		email: function (me) {
			return me.user ? me.user.emailAddress : undefined;
		},
		baseUrl: function (me) {
			return me.urls ? me.urls.base : undefined;
		},
		apis: function (me) {
			return me.urls ? me.urls.apis : undefined;
		},
		urls: function (me) {
			return me.urls ? me.urls : undefined;
		}
	}
};
module.exports = me;
