var me = {

    url: '/1.1/account/verify_credentials.json',
    params: {},
    fields: {
    	id: 'id_str',
        name: '=',
        alias: 'screen_name',
        bio: 'description',
        avatar: 'profile_image_url_https',
        location: '=',
        language: 'lang',
        timezone: 'time_zone',
        website: 'url'
    }
};

module.exports = me;