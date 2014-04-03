module.exports = function() {
    return {
        location: {
            hash: '',
            href: '',
            reload: function() {

            },
            protocol: 'http:',
            host: 'mytest',
            pathname: '/'
        },
        createElement: function(elt) {
            console.log('creating element ' + elt);
        }
    };
};