/*
OAuth daemon
Copyright (C) 2013 Webshell SAS

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
 any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

(function() {
	"use strict";
	var config = {
		oauthd_url: '{{auth_url}}'
	};

	config.oauthd_base = getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];

	var oauth_result;
	(function parse_urlfragment() {
		var results = /[\\#&]oauthio=([^&]*)/.exec(document.location.hash);
		if (results) {
			document.location.hash = '';
			oauth_result = decodeURIComponent(results[1].replace(/\+/g, " "));
		}
	})();

	function getAbsUrl(url) {
		if (url[0] === '/')
			url = document.location.protocol + '//' + document.location.host + url;
		else if ( ! url.match(/^.{2,5}:\/\//))
			url = document.location.protocol + '//' + document.location.host + document.location.pathname + '/' + url;
		return url;
	}

	function sendCallback(opts) {
		var data;
		var err;
		try {
			data = JSON.parse(opts.data);
		} catch (e) {}

		if ( ! data || ! data.provider)
			return;

		if (opts.provider && data.provider.toLowerCase() !== opts.provider.toLowerCase())
			return;

		if (data.status === 'error' || data.status === 'fail') {
			err = new Error(data.message);
			err.body = data.data;
			return opts.callback(err);
		}

		if (data.status !== 'success' || ! data.data) {
			err = new Error();
			err.body = data.data;
			return opts.callback(err);
		}

		if ( ! opts.provider)
			data.data.provider = data.provider;

		return opts.callback(null, data.data);
	}

	window.OAuth = {
		initialize: function(public_key) {
			config.key = public_key;
		},
		popup: function(provider, opts, callback) {
			var wnd;
			if ( ! config.key)
				return callback(new Error('OAuth object must be initialized'));
			if (arguments.length == 2) {
				callback = opts;
				opts = undefined;
			}

			var url = config.oauthd_url + '/' + provider + "?k=" + config.key
			url += '&d=' + encodeURIComponent(getAbsUrl('/'));
			if (opts)
				url += "&opts=" + encodeURIComponent(JSON.stringify(opts));

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

			var opts = {provider:provider};
			function getMessage(e) {
				if (e.source !== wnd || e.origin !== config.oauthd_base)
					return;
				opts.data = e.data;
				return sendCallback(opts);
			}
			opts.callback = function(e, r) {
				if (window.removeEventListener)
					window.removeEventListener("message", getMessage, false);
				else if (window.detachEvent)
					window.detachEvent("onmessage", getMessage);
				else if (document.detachEvent)
					document.detachEvent("onmessage", getMessage);
				opts.callback = function() {};
				return callback(e,r);
			};

			if (window.attachEvent)
				window.attachEvent("onmessage", getMessage);
			else if (document.attachEvent)
				document.attachEvent("onmessage", getMessage);
			else if (window.addEventListener)
				window.addEventListener("message", getMessage, false);

			setTimeout(function() {
				opts.callback(new Error('Authorization timed out'));
			}, 600 * 1000);

			wnd = window.open(url, "Authorization", wnd_options);
			if (wnd)
				wnd.focus();
		},
		redirect: function(provider, opts, url) {
			if (arguments.length == 2) {
				url = opts;
				opts = undefined;
			}
			var redirect_uri = encodeURIComponent(getAbsUrl(url));
			url = config.oauthd_url + '/' + provider + "?k=" + config.key;
			url += "&redirect_uri=" + redirect_uri;
			if (opts)
				url += "&opts=" + encodeURIComponent(JSON.stringify(opts));
			document.location.href = url;
		},
		callback: function(provider, callback) {
			if ( ! oauth_result)
				return;

			if (arguments.length === 1)
				return sendCallback({data:oauth_result, callback:provider});

			return sendCallback({data:oauth_result, provider:provider, callback:callback});
		}
	};
})();