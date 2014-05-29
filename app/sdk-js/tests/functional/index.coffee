config = require("./testconfig").config

provider = "./providers/" + casper.cli.options.provider || "./providers/facebook"

config_prov = require(provider).config

utils = require('utils')
test = require('./testsuite').launch


test casper, config_prov, config, utils