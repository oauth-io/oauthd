module.exports = function() {
	var defer = {
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
			defer.methods.failure.arguments = arguments;
			if (defer.methods.failure.method) {
				defer.methods.failure.method.apply(this, defer.methods.failure.arguments);
			}
		},
		resolve: function() {
			defer.methods.success.arguments = arguments;
			if (defer.methods.success.method) {
				defer.methods.success.method.apply(this, defer.methods.success.arguments);
			}
		},
		promise: function() {
			return {
				done: function(f) {
					defer.methods.success.method = f;
					if (defer.methods.success.arguments) {
						defer.methods.success.method.apply(this, defer.methods.success.arguments);
					}
					return defer.promise();
				},
				fail: function(f) {
					defer.methods.failure.method = f;
					if (defer.methods.failure.arguments) {
						defer.methods.failure.method.apply(this, defer.methods.failure.arguments);
					}
					return defer.promise();
				}
			};
		}
	};
	return defer;
};