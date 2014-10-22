
module.exports = function(grunt) {
	grunt.initConfig({
		less: {
			production: {
				options: {
					paths: ["assets/css"],
					cleancss: true
				},
				files: {
					"stylesheets/main.css": "less/main.less"
				}
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-less');

	grunt.registerTask('default', ['less']);
};