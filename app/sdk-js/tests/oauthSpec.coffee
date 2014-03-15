config = require("./testconfig").config

config_facebook = require('./facebook_config').config

test = require('./testsuite').launch

test casper, config_facebook, config