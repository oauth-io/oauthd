var events = require('events');
var eventEmitter = new events.EventEmitter();
var document = {};
module.exports = function(config) {
    return {
        popup: {},
        open: function(url, name, options) {
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
            setHash: function(newHash) {},
            changeHref: function(newLocation) {
                document.location.href = newLocation;
            }
        },
        screenX: 1600,
        screenY: 600,
        outerWidth: 1680,
        outerHeight: 1050,
        addEventListener: function(eventName, callback) {
            eventEmitter.on(eventName, function() {
                callback({
                    origin: config.oauthd_base
                });
            });
        },
        emitEvent: function(eventName) {
            eventEmitter.emit(eventName);
        },
        setDocument: function(doc) {
            document = doc;
        }
    };
};