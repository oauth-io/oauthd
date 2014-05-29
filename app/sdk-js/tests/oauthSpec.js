// var casper = require('casper').create();

var UserFirstName = "";
var UserLastName = "";
var UserEmail = "";
var UserPassword = "";
var UserFbId = 0;
var UserInfoGraphUrl = "";


var require = patchRequire(require);
var config = require('./testconfig').config;

casper.test.begin('Testing Facebook Connect', 5, function suite(test) {



    casper.start(function() {
        window.__flag = false;
    });
    UserEmail = config.facebook.account.email;
    UserPassword = config.facebook.account.password;


    casper.thenOpen('https://oauth.io', function() {
        var base = this;
        base.echo(base.getTitle());

        //Testing OAuth
        var OAuth = base.evaluate(function() {
            return window.OAuth;
        });
        base.test.assert(OAuth !== undefined, 'OAuth is defined');


        var version = base.evaluate(function() {
            return window.OAuth.getVersion();
        });

        base.test.assert(typeof version === 'string', 'OAuth.version is defined');


        //Initialize
        var init_worked = base.evaluate(function(config) {
            try {
                window.OAuth.initialize(config.appkey);
                return true;
            } catch (e) {
                return false;
            }
        }, {
            config: config
        });
        base.test.assert(init_worked, 'Initialize is set');



        var launch_popup = base.evaluate(function() {
            try {
                var popupres = window.OAuth.popup('facebook');

                popupres.done(function(res) {
                    window.__flag = true;
                    window.facebook_res = res;
                    window.callPhantom({
                        finished: true
                    });
                });
                popupres.fail(function() {
                    window.__flag = true;
                    window.facebook_failed = arguments;

                    window.callPhantom({
                        finished: true
                    });
                });
                return true;
            } catch (e) {
                return false;
            }
        });

        base.test.assert(launch_popup, 'Popup method : defined and callable');
    });




    casper.waitForPopup(/oauth\.io/, function() {
        test.assertEquals(this.popups.length, 1, 'Popup method : call loaded popup');
    }, function() {

    }, 1000);

    casper.then(function() {
        this.echo('Waiting 1 second for facebook form to load');
    });

    casper.wait(1000, function() {

    });

    casper.withPopup(/oauth\.io/, function() {
        this.echo('Form loaded');
        this.fill("form#login_form", {
            'email': UserEmail,
            'pass': UserPassword
        }, false);
        this.click("#u_0_1");
    });

    casper.withPopup(/oauth\.io/, function() {
        console.log('Filled form and clicked ok.');
    });

    casper.wait(5000);

    //Testing Me method
    casper.waitFor(function() {
        return this.getGlobal('__flag') === true;
    }, function() {
        window.__flag = false;
        var me_defined = this.evaluate(function() {
            window.__flag = false;
            try {
                window.facebook_res.me(['name'])
                    .done(function(data) {
                        window.__flag = true;
                        window.me_info = data
                    });
                return true;
            } catch (e) {
                return false;
            }
        });

        this.test.assert(me_defined, 'Me method : defined and callable');
    });

    casper.waitFor(function() {
        return this.getGlobal('__flag') === true;
    }, function() {
        var me = this.evaluate(function() {
            return window.me_info;
        });
        this.test.assert(me.name == "Jean-René Dupont", 'Me method : filtered info retrieval returned correct object');
    });

    //standard endpoints
    //GET
    casper.then(function() {
        var get_defined = this.evaluate(function() {
            window.__flag = false;
            window.me_info = undefined;
            try {
                window.facebook_res.get('/me')
                    .done(function(data) {
                        window.__flag = true;
                        window.me_info = data;
                    });
                return true;
            } catch (e) {
                return false;
            }
        });
        this.test.assert(get_defined, 'Get method : defined and callable');
    });

    casper.waitFor(function() {
        return this.getGlobal('__flag') === true;
    }, function() {
        var me = this.evaluate(function() {
            return window.me_info;
        });
        this.test.assert(me.first_name == 'Jean-René', 'Get method : got request result as predicted');
    });


    casper.run();
});