<a href="http://travis-ci.org/oauth-io/oauthd"><img src="https://secure.travis-ci.org/oauth-io/oauthd.png" alt="Build Status" style="max-width:100%;"></a>

# OAuth daemon

The Oauth Daemon is the open source version of the [OAuth.io](https://oauth.io) core. This is a background api server that runs on your own server that allow your clients to authenticate to any 70+ available OAuth provider.

![OAuthd Keys manager](https://oauth.io/img/oauthd-keymanager.png "Keys manager")

## Prerequisites

- A working redis database >= v2.4, check [Redis quickstart](http://redis.io/topics/quickstart) for a properly installation
- nodejs >= v0.8.2
- npm >= v1.1
- needed packages for npm dependencies: python curl bash

## Installation

Run the redis server if it's not running yet.

	(sudo) npm install -g forever oauthd
	oauthd config
	oauthd start

You can use `oauthd [start|stop|status|startsync|config]` to manage your daemon.

## Development installation

    (sudo) npm install -g coffee-script grunt-cli forever
    git clone git://github.com/oauth-io/oauthd.git

In the cloned project dir, issue:

    npm install

`npm` will install dependencies listed in `package.json` and compile coffee files.

If you have a problem during `npm install` you may want to restart the compilation step by doing:

	grunt

To start or stop oauthd, just use
`npm [start|stop]` in the oauthd folder.

If you want to start oauthd in debug mode, you can also use `grunt server`

This will launch nodemon and watch/recompile modified files.


## Using OAuth daemon

You may configure config.js in oauthd folder, to configure your ports, connection with redis, enable ssl etc.
You can also write a config.local.js file that will overwrite existing fields of config.js.

By default, you can access it by [http://localhost:6284/admin](http://localhost:6284/admin).

![OAuthd signin](https://oauth.io/img/oauthd-signin.png "OAuthd")

Then the admin interface is available to your url / port set into config.js, at /admin.

The first time you connect, the given login & pass will be registered as the admin user. If you lose it, you can reset the login with `node ./tools/login_reset.js` in the oauthd folder.

Then you can include the generated js sdk from oauthd to use it on your sites. By example for a local test:
`<script src="http://localhost:6284/download/latest/oauth.js"></script>`


## Contributing & Licenses

If you want to contribute to this project, you can directly make pull requests to our Github repository that we regulary check.

Copyright (C) 2013 Webshell SAS

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

⇨ [More infos about AGPL](http://www.tldrlegal.com/license/gnu-affero-general-public-license-v3-%28agpl-3.0%29)
