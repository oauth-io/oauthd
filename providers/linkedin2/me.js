var me = {

    url: '/v1/people/~:(id, first-name,last-name,headline,picture-url,email-address)?format=json',
    params: {},
    fields: {
        id: 'id',
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