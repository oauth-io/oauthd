var me = {

    url: '/v1/people/~:(first-name,last-name,headline,picture-url)?format=json',
    params: {},
    fields: {
        name: function(me) {
            return me.firstName + ' ' + me.lastName;
        },
        firstname: 'firstName',
        lastname: 'lastName',
        alias: 'screen_name',
        bio: 'headline',
        avatar: 'pictureUrl'
    }
};

module.exports = me;