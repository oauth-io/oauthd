var me = {
	fetch: [
		function(fetched_elts) {
			return 'https://launchpad.37signals.com/authorization.json';
		}
	],
	params: {},
	fields: {
		id: function(me) {
			return me.identity.id;
		},
		name: function(me) {
			return me.identity.first_name + ' ' + me.identity.last_name;
		},
		email: function(me) {
			return me.identity.email_address;
		}
	}
};
module.exports = me;