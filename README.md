# OAuth daemon

The Oauth Daemon is the open source version of the [OAuth.io](https://oauth.io) core. This is a background api server that runs on your own server that allow your clients to authenticate to any 70+ available OAuth provider.

![OAuthd Keys manager](https://oauth.io/img/oauthd-keymanager.png "Keys manager")

## Prerequisites

- A working redis database >= v2.4, check [Redis quickstart](http://redis.io/topics/quickstart) for a properly installation
- nodejs >= v0.8.2
- npm >= v1.1

## Installing global dependencies

`(sudo) npm install -g coffee-script grunt grunt-cli forever`

## Installing OAuth daemon

`npm install oauthd`

## Using OAuth daemon

Run the redis server if it's not running yet.

To start, stop or restart oauthd, just use
`npm [start|stop|restart]` in oauthd folder.

By default, you can access it by [http://localhost:6284/admin](http://localhost:6284/admin).

![OAuthd signin](https://oauth.io/img/oauthd-signin.png "OAuthd")

The first time you connect, the given login & pass will be registered as the admin user, so don't forget it !

Then you can include the generated js sdk from oauthd to use it on your sites. By example for a local test:
`<script src="http://localhost:6284/download/latest/oauth.js"></script>`

You may configure config.js in oauthd folder, to configure your ports, connection with redis, enable ssl etc.

Then the admin interface is available to your url / port set into config.js, at /admin.

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
