 describe("OAuth.get method", function() {
     beforeEach(function(done) {
         values = require('../init_tests')();
         values.window.OAuth.initialize('akey');
         values.window.OAuth.redirect('facebook', '');

         values = require('../init_tests')({
             hash: '#oauthio=' + encodeURIComponent(JSON.stringify({
                 provider: 'facebook',
                 state: values.sha1.create_hash(),
                 status: 'success',
                 data: {
                     oauth_token: 'mytoken',
                     oauth_token_secret
                     request: {

                     }
                 }
             }))
         });
         values.window.OAuth.callback('facebook')
             .done(function(r) {
                 values.r = r;
                 done();
             })
             .fail(function(e) {
                 expect(e).not.toBeDefined();;
                 done();
             });
     });

     it("should exist", function() {
         expect(values.r.get).toBeDefined();
         expect(typeof values.r.get).toBe('function');
     });

     it("to be callable", function(done) {
         values.r.get('/me', function() {
             expect(true).toBe(true);
         });
     });




 });