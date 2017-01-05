[![Build Status](https://travis-ci.org/oauth-io/oauthd.svg?branch=master)](https://travis-ci.org/oauth-io/oauthd)  [![npm version](https://badge.fury.io/js/oauthd.svg)](https://badge.fury.io/js/oauthd) [![dependencies Status](https://david-dm.org/oauth-io/oauthd/status.svg)](https://david-dm.org/oauth-io/oauthd)


**oauthd**, also known as the 'oauth Daemon' is the open source version of
[OAuth.io](https://oauth.io)'s core.

## What is it?

It is a solution based on node.js that enables you to set
up and run your own stand-alone, completly free, web Background API Server.

## Main features

This server will allows you to authenticate and to integrate the common API
providers, with just three lines of JavaScript, completely abstracting away
the complexity of OAuth integration.
By using the oauth Daemon, you are free to focus your attention on product
development instead of losing time on API integration using OAuth.

#### Exhaustive: compatible with 100+ providers
**oauthd** works with all your favorite platforms, whether social (Facebook,
Twitter, LinkedIn...) or SaaS (Mailchimp, Paypal, Stripe...).
#### Simplified API calls
With **oauthd**, you can make API calls instead of dealing with complex OAuth flows.
Abstract tokens with the 'Request API' and get user info in a unified way,
no matter which provider you are using. The API also lets you perform CRUD
actions on behalf of users.
#### Secured encrypted API
**oauthd** lets you choose an authorization flow that fits your needs (client-side
or server-side). It secures providers API access with SSL encryption and allows
you to specify domains/url restrictions for more security.
#### Integrate in less than 90 seconds
Through the **oauthd** default administration interface, you can start adding OAuth
providers to your app and  get a public key to start using these APIs
right away.

## Modular design

**oauthd** is highly extendable thanks to a plugin management system based on Git.
Each plugin can brings its own layer of features.
Anyone can create his own plugin and is free to share it with the Open Source Community.
We are eager to see you contribute!

Default plugins are furnished to ensure a working minimum environment, with:
- The request system plugin
- The '/me' feature plugin
- The default auth plugin, which lets you administrate **oauthd**
- The default back office front plugin, which lets you manage apps, providers and access to other plugins' configuration from the browser

You can learn more about plugins development
[here](https://github.com/oauth-io/oauthd/wiki/Plugins-development).

## Installation

Currently, **oauthd** relies on [node.js](http://nodejs.org/), [npm](https://www.npmjs.org/), [redis](http://redis.io/) and the npm package [grunt-cli](https://www.npmjs.org/package/grunt-cli) to work.
Check out our [quickstart tutorial](https://github.com/oauth-io/oauthd/wiki/Quickstart) to bootstrap your **oauthd** server.

As soon as you are done with pre-requisites, you can simply install **oauthd** from npm, by executing the following command:

```sh
(sudo) npm install -g oauthd
```

Once you've installed the **oauthd** npm package globally, you will have the
`oauthd` command available in your shell. This command allows you to create
new *oauthd instances*, start them, and manage their plugins.

Learn more about the **oauthd**
[configuration](https://github.com/oauth-io/oauthd/wiki/Configuration) and the
[command line features](https://github.com/oauth-io/oauthd/wiki/Command-Line-Interface).

There is also a Docker container for oauthd if you want to try running oauthd inside a VM:
Docker hub [repository](https://registry.hub.docker.com/u/vinc/oauthd-instance/).

## Usage

You can use the **oauthd** server from you app directly through the API or use one
of our SDKs:

**Client side SDKs**
- JavaScript
- iOS
- Phonegap
- Android

**Server side SDKs**
- Nodejs
- PHP
- Go

Learn more about the **oauthd**
[apis](https://github.com/oauth-io/oauthd/wiki/API) and the
[oauthd-sdks](https://github.com/oauth-io/oauthd/wiki/Server-and-client-side-SDKs).

## Contact

Have a question?

- Drop an email at support@oauth.io
- [@OAuth_io](https://twitter.com/OAuth_io) on Twitter

## Contributing to this project

Anyone and everyone is welcome to contribute. Please take a moment to review the guidelines for contributing.

- [Bug reports](https://github.com/oauth-io/oauthd/issues)
- [Feature requests](https://github.com/oauth-io/oauthd/issues)
- [Pull requests](https://github.com/oauth-io/oauthd/pulls)

## License & Copyright

Copyright (C) 2017 Webshell SAS
[https://github.com/oauth-io/oauthd](https://github.com/oauth-io/oauthd) and other contributors

Licensed under the Apache License 2.0
