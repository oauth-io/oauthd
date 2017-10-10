var me = {
    fetch: [
		{
			url: '/users/get_current_account',
			method: 'post',
			export: {
                name: function(result) { return result.name	},
				email: function(result) { return result.email },
				country: function(result) { return result.country },
				locale: function(result) { return result.locale },
				avatar: function(result) { return result.profile_photo_url }
            }
		},
        function(fetched_elts) {
            return fetched_elts;
        }
    ],
    params: {},
    fields: {
        name: function(me) {
			if (me.name) {
				return me.name.display_name
			}
			return ""
		},
        email: '=',
        location: 'country',
		locale: 'locale',
		avatar: 'profile_photo_url'
    }
};
module.exports = me;