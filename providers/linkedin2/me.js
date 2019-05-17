var me = {
    fetch: [
        {
          url: '/v2/emailAddress?q=members&projection=(elements*(handle~))',
          export: {
            emails: function (result) {
              return result;
            }
          }
        },
        {
          url: '/v2/me?projection=(id,localizedFirstName,localizedLastName,localizedHeadline,profilePicture(displayImage~:playableStreams),vanityName)',
          export: {
            user: function (result) {
              return result;
            }
          }
        },
        function (fetched_elts) {
          return fetched_elts;
        }
    ],
    params: {},
    fields: {
        id: function (me) {
            return me.user.id || undefined;
        },
        name: function(me) {
            var name = [];

            if (!!me.user.localizedFirstName) {
                name.push(me.user.localizedFirstName);
            }

            if (!!me.user.localizedLastName) {
                name.push(me.user.localizedLastName);
            }

            return name.join(' ');
        },
        firstname: function (me) {
            return me.user.localizedFirstName || undefined;
        },
        lastname: function (me) {
            return me.user.localizedLastName || undefined;
        },
        alias: function (me) {
            return me.user.vanityName || undefined;
        },
        bio: function (me) {
            return me.user.localizedHeadline || undefined;
        },
        avatar: function(me) {
            try {
                return me.user.profilePicture['displayImage~'].elements.pop().identifiers.pop().identifier;
            } catch (e) {
                return undefined;
            }
        },
        email: function(me) {
            try {
                return me.emails.elements.pop()['handle~'].emailAddress;
            } catch (e) {
                return undefined;
            }
        },
        url: function(me) {
            if (!me.user.vanityName) {
                return undefined;
            }

            return 'https://www.linkedin.com/in/' + me.user.vanityName;
        }
    }
};

module.exports = me;
