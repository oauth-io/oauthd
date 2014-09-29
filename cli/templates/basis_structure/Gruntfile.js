'use strict';

var fs = require('fs');

module.exports = function(grunt) {

    // Project configuration.
    var gruntConf = {
        watch: {
            options: {
                nospawn: true
            }
        },
        coffee: {},
        subgrunt: {}
    };

    var tasks = [];

    // var added_plg = fs.readdirSync(process.cwd() + '/plugins');
    // var config = require('./config');
    var plugins = require('./plugins.json');
    for (k in plugins) {
        added_plg.push(k);
    }
    
    for (var i in added_plg) {
        var plugin = added_plg[i];

        if (fs.existsSync(process.cwd() + '/plugins/' + plugin + '/gruntConfig.js')) {
            var task = require('./plugins/' + plugin + '/gruntConfig').call(this, gruntConf);
            if (task)
                tasks.push(task);
        }
        if (fs.existsSync(process.cwd() + '/plugins/' + plugin + '/Gruntfile.js')) {
            gruntConf.subgrunt[plugin] = {
                options: {},
                projects: {}
            };
            gruntConf.subgrunt[plugin].projects['./plugins/' + plugin] =  'default';
        }
    }

    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-subgrunt');

    // Default task.
    grunt.registerTask('default', ['coffee', 'subgrunt']);
    grunt.registerTask('test', ['nodeunit']);
};