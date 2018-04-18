'use strict';
/* jshint camelcase: false */

var me = {
  fetch: [
    function(fetched_elts) {
      return 'https://api.line.me/v2/profile';
    }
  ],
  params: {},
  fields: {
    userId: function (me) {
      return me.userId;
    },
    pictureUrl: function (me) {
      return me.pictureUrl;
    },
    displayName: function (me) {
      return me.displayName;
    },
    statusMessage: function(me) {
      return me.statusMessage;
    }
  }
};

module.exports = me;
