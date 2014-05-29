config = require("./testconfig").config

if casper.cli.options.provider != undefined
	provider = "./providers/" + casper.cli.options.provider
else
	provider = "./providers/facebook"

config_prov = require(provider).config

utils = require('utils')
test = require('./testsuite').launch


test casper, config_prov, config, utils