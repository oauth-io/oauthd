'use strict';

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    watch: {
        options: {
            nospawn: true
        },
        compile: {
            files: ['app/adm/{,*/}*.coffee','app/coffee/{,*/}*.coffee','app/less/{,*/}*.less'],
            tasks: ['concurrent:compile']
        },
        coffeeTest: {
            files: ['test/spec/{,*/}*.coffee'],
            tasks: ['coffee:test']
        }
    },
    coffee: {
      dist: {
        expand: true,
        cwd: "app/coffee",
        src: ['{,*/}*.coffee'],
        dest: 'app/js',
        ext: '.js',
        options: {
          bare: true
        },
      },

      adm: {
        expand: true,
        cwd: "app/adm",
        src: ['{,*/}*.coffee'],
        dest: 'app/adm/js',
        ext: '.js',
        options: {
          bare: true
        },
      },

      test: {
        expand: true,
        cwd: 'test/spec',
        src: '**/*.coffee',
        dest: '.tmp/spec',
        ext: '.js'
      }
    },
    nodeunit: {
      files: ['test/**/*_test.js']
    },
    jshint: {
      options: {
        jshintrc: '.jshintrc'
      },
      gruntfile: {
        src: 'Gruntfile.js'
      },
      server: {
        src: ['server/**/*.js']
      },
      test: {
        src: ['test/**/*.js']
      },
    },
    clean: {
      build: ['app/js/**/*.js','app/css/**/main.css']
    },
    nodemon: {
      server: {
        options: {
          file: 'server/oauth.coffee'
        }
      }
    },
    less: {
      dist: {
        files: {
          "app/css/main.css": "app/less/main.less"
        }
      }
    },
    concurrent: {
      server: {
        tasks: ['watch:compile','nodemon:server'],
        options: {
          logConcurrentOutput: true
        }
      },
      compile: {
        tasks: ['coffee:adm', 'coffee:dist', 'less:dist'],
        options: {
          logConcurrentOutput: true
        }
      },
      test: {
        tasks: ['jshint:test', 'nodeunit'],
        options: {
          logConcurrentOutput: true
        }
      }
    },
  });

  grunt.registerTask('server', function (target) {
    grunt.task.run([
      'concurrent:compile',
      'concurrent:test',
      'concurrent:server'
    ]);
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-nodeunit');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-concurrent');
  grunt.loadNpmTasks('grunt-nodemon');
  grunt.loadNpmTasks('grunt-contrib-coffee');

  // Default task.
  grunt.registerTask('default', ['concurrent:compile', 'concurrent:test']);

};
