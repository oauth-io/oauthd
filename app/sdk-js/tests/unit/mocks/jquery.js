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
                    success: {
                        method: undefined,
                        arguments: undefined
                    },
                    failure: {
                        method: undefined,
                        arguments: undefined
                    }
                },
                reject: function() {
                    def.methods.failure.arguments = arguments;
                    if (def.methods.failure.method) {
                        def.methods.failure.method.apply(this, def.methods.failure.arguments);
                    }
                },
                resolve: function() {
                    def.methods.success.arguments = arguments;
                    if (def.methods.success.method) {
                        def.methods.success.method.apply(this, def.methods.success.arguments);
                    }
                },
                promise: function() {
                    return {
                        done: function(f) {
                            def.methods.success.method = f;
                            if (def.methods.success.arguments) {
                                def.methods.success.method.apply(this, def.methods.success.arguments);
                            }
                            return def.promise();
                        },
                        fail: function(f) {
                            def.methods.failure.method = f;
                            if (def.methods.failure.arguments) {
                                def.methods.failure.method.apply(this, def.methods.failure.arguments);
                            }
                            return def.promise();
                        }
                    };
                }
            };
            return def;
        }
    };
    return jquery;
};