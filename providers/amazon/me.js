var me = {
	fetch: [
		function(fetched_elts) {
			return 'https://api.amazon.com/user/profile';
		}
	],
	params: {},
	fields: {
		id: function(me) {
			return me.user_id;
		},
		name: function(me) {
			return me.name;
		},
		email: function(me) {
			return me.email;
		},
		zipcode: function(me) {
			return me.postal_code;
		}
	}
};
module.exports = me;