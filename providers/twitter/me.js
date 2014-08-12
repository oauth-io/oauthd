var me = {

    url: '/1.1/account/verify_credentials.json',
    params: {},
    fields: {
        name: '=',
        alias: 'screen_name',
        bio: 'description',
        avatar: 'profile_image_url'
    }
};

module.exports = me;