var me = {

    url: '/v1/people/~:(first-name,last-name,headline,picture-url,email-address)?format=json',
    params: {},
    fields: {
        name: function(me) {
            return me.firstName + ' ' + me.lastName;
        },
        firstname: 'firstName',
        lastname: 'lastName',
        alias: 'screen_name',
        bio: 'headline',
        avatar: 'pictureUrl',
        email: 'emailAddress'
    }
};

module.exports = me;