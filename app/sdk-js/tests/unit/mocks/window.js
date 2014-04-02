var events = require('events');
var eventEmitter = new events.EventEmitter();

module.exports = function(document) {
    return {
        popup: {},
        open: function(url, name, options) {
            console.log("OPENED POPUP", options);
            this.popup.url = url;
            this.popup.name = name;
            this.popup.options = options;
        },
        location_operations: {
            reload: function() {
                console.log('RELOADING');
            },
            getHash: function() {
                return document.location.hash;
            },
            setHash: function(newHash) {
                console.log('SETTING NEW HASH', newHash);
            },
            changeHref: function(newLocation) {
                console.log("CHANGING HREF TO", newLocation);
                document.location.href = newLocation;
            }
        },
        screenX: 1600,
        screenY: 600,
        outerWidth: 1680,
        outerHeight: 1050,
        addEventListener: function(eventName, callback) {
            eventEmitter.on(eventName, callback);
        },
        emitEvent: function(eventName) {
            eventEmitter.emit(eventName);
        }
    };
};