config = require("./testconfig").config

config_facebook = require('./facebook_config').config
utils = require('utils')
test = require('./testsuite').launch


test casper, config_facebook, config, utils