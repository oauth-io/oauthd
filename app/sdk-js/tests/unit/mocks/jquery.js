module.exports = function() {
    jquery = {
        ajax: function() {

        },
        get: function() {

        },
        post: function() {

        },
        Deferred: function() {
            var def = {
                methods: {
                    success: function() {},
                    failure: function() {}
                },
                reject: function() {
                    def.methods.failure.apply(this, arguments);
                },
                resolve: function() {
                    def.methods.success.apply(this, arguments);
                },
                promise: function() {
                    return {
                        done: function(f) {
                            def.methods.success = f;
                        },
                        fail: function(f) {
                            def.methods.failure = f;
                        }
                    };
                }
            };
            return def;
        }
    };
    return jquery;
};