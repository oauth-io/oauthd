'use strict';
/* jshint camelcase: false */

var me = {
  fetch: [
    {
      url: '/user/emails',
      export: {
        emails: function (result) {
          return result;
        }
      }
    },
    {
      url: '/user',
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
      return '' + me.user.id;
    },
    name: function (me) {
      return me.user.name;
    },
    company: function (me) {
      return me.user.company;
    },
    alias: function (me) {
      return me.user.login;
    },
    bio: function (me) {
      return me.user.bio;
    },
    avatar: function (me) {
      return me.user.avatar_url;
    },
    email: function (me) {
      var email = null;
      if (me.emails && me.emails.forEach) {
        me.emails.forEach(function (em) {
          if(em.primary === true && em.verified === true) {
            email = em.email;
          }
        });
      }
      return email;
    },
    emails: function (me) {
      return me.emails;
    },
    location: function (me) {
      return me.user.location;
    }
  }
};

module.exports = me;