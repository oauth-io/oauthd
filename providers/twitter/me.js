var me = {
	url: '/1.1/account/verify_credentials.json?include_email=true',
	params: {},
	fields: {
		id: 'id_str',
		name: '=',
		alias: 'screen_name',
		email: '=',
		bio: 'description',
		avatar: 'profile_image_url_https',
		location: '=',
		language: 'lang',
		timezone: 'time_zone',
		website: 'url',
		url: function(me) {
			return 'https://twitter.com/' + me.screen_name;
		}
	}
};

module.exports = me;