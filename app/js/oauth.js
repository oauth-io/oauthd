(function() {
	"use strict";
	var config = {
		oauthd_url: '{{auth_url}}'
	};

	function bindMessage(provider, callback) {
		setTimeout(function() {
			callback(new Error('Authorization timed out'));
			callback = function() {};
		}, 600 * 1000);
		function getMessage(e) {
			var data;
			try {
				data = JSON.parse(e.data);
			} catch (err) { }

			if ( ! data || ! data.provider || data.provider.toLowerCase() !== provider)
				return;

			if (window.removeEventListener)
				window.removeEventListener("message", getMessage, false);
			else if (window.detachEvent)
				window.detachEvent("onmessage", getMessage);
			else if (document.detachEvent)
				document.detachEvent("onmessage", getMessage);

			callback(null, data);
		}
		return getMessage;
	}

	window.OAuth = {
		initialize: function(public_key) {
			config.key = public_key;
		},
		popup: function(provider, callback) {
			var url = config.oauthd_url + '/' + provider + "?k=" + config.key;

			// create popup
			var wnd_settings = {
				width: Math.floor(window.outerWidth * 0.8),
				height: Math.floor(window.outerHeight * 0.5)
			};
			if (wnd_settings.height < 350)
				wnd_settings.height = 350;
			if (wnd_settings.width < 800)
				wnd_settings.width = 800;
			wnd_settings.left = window.screenX + (window.outerWidth - wnd_settings.width) / 2;
			wnd_settings.top = window.screenY + (window.outerHeight - wnd_settings.height) / 8;
			var wnd_options = "width=" + wnd_settings.width + ",height=" + wnd_settings.height;
			wnd_options += ",toolbar=0,scrollbars=1,status=1,resizable=1,location=1,menuBar=0";
			wnd_options += ",left=" + wnd_settings.left + ",top=" + wnd_settings.top;

			if (window.attachEvent)
				window.attachEvent("onmessage", bindMessage(provider, callback));
			else if (document.attachEvent)
				document.attachEvent("onmessage", bindMessage(provider, callback));
			else if (window.addEventListener)
				window.addEventListener("message", bindMessage(provider, callback), false);

			var wnd = window.open(url, "Authorization", wnd_options);
			if (wnd)
				wnd.focus();
		},
		redirect: function(provider, url) {
			url = config.oauthd_url + '/' + provider + "?k=" + config.key + "&redirect_uri=" + url;
			document.location.href = url;
		}
	};
})();