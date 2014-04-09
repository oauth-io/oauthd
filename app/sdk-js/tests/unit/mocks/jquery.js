module.exports = function() {
    jquery = {
        ajaxOptionsHandler: undefined,
        setAjaxOptionsHandler: function(callback) {
            jquery.ajaxOptionsHandler = callback;
        },
        ajax: function(options) {
            var ret = {
                methods: {
                    success: {
                        arguments: undefined,
                        method: undefined
                    },
                    failure: {
                        arguments: undefined,
                        method: undefined
                    }
                },
                reject: function() {
                    ret.methods.failure.arguments = arguments;
                    if (ret.methods.failure.method) {
                        ret.methods.failure.method.apply(this, ret.methods.failure.arguments);
                    }
                },
                resolve: function() {
                    ret.methods.success.arguments = arguments;
                    if (ret.methods.success.method) {
                        ret.methods.success.method.apply(this, ret.methods.success.arguments);
                    }
                },
                promise: function() {
                    return {
                        done: function(f) {
                            ret.methods.success.method = f;
                            if (ret.methods.success.arguments) {
                                ret.methods.success.method.apply(this, ret.methods.success.arguments);
                            }
                            return ret.promise();
                        },
                        fail: function(f) {
                            ret.methods.failure.method = f;
                            if (ret.methods.failure.arguments) {
                                ret.methods.failure.method.apply(this, ret.methods.failure.arguments);
                            }
                            return ret.promise();
                        }
                    };
                }
            };
            var handling_method = jquery.ajaxOptionsHandler || function() {
                    return {
                        __success : false
                    };
                };
            var handled = jquery.ajaxOptionsHandler(options);
            if (handled.__status) {
                ret.resolve(handled);
            } else {
                ret.reject(handled);
            }
            return ret.promise();
        },
        get: function() {},
        post: function() {},
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
        },
        when: function (promise) {
            return promise;
        }
    };
    return jquery;
};