var me = {
	url: "/oauth/v1/access-tokens/{{access_token}}",
	params: {},
	fields: {
		user_id: function (me) {
			return me.user_id
		},
		email: function (me) {
			return me.user
		}
	}
};

module.exports = me;
